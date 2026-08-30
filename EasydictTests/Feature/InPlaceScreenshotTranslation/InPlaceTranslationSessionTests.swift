//
//  InPlaceTranslationSessionTests.swift
//  EasydictTests
//
//  Created by Eric Pan on 2026/8/30.
//  Copyright © 2026 izual. All rights reserved.
//

import AppKit
import Defaults
import Testing

@testable import Easydict

// MARK: - InPlaceTranslationSessionTests

/// Exercises live-session lifecycle, invalidation scope, refresh, and unchanged-frame suppression.
@MainActor
@Suite("In-place Translation Session", .serialized, .tags(.inPlaceTranslation, .unit))
struct InPlaceTranslationSessionTests {
    // MARK: Internal

    @Test("Pause stops capture and resume restarts capture with a forced refresh")
    func pausesAndResumesLiveCapture() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        #expect(await harness.frameSource.metrics().startCount == 1)
        #expect(await harness.recognizer.requestCount() == 1)

        await harness.session.setLiveUpdatesEnabled(false)
        #expect(harness.viewModel.lifecycle == .paused)
        #expect(await harness.frameSource.metrics().stopCount == 1)

        await harness.session.setLiveUpdatesEnabled(true)
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        #expect(await harness.frameSource.metrics().startCount == 2)
        #expect(await harness.recognizer.requestCount() == 2)

        await harness.session.stop()
        #expect(harness.viewModel.lifecycle == .stopped)
        #expect(await harness.frameSource.metrics().stopCount == 2)
    }

    @Test("Target and provider changes retranslate while source and refresh rerun OCR")
    func invalidatesOnlyRequiredPipelineStages() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 1)

        await harness.session.setTargetLanguage(.japanese)
        #expect(await waitUntil { await harness.translator.requestCount() == 2 })
        #expect(await harness.recognizer.requestCount() == 1)

        await harness.session.setServiceIdentifier("provider-b")
        #expect(await waitUntil { await harness.translator.requestCount() == 3 })
        #expect(await harness.recognizer.requestCount() == 1)

        await harness.session.setSourceLanguage(.japanese)
        #expect(await waitUntil { await harness.recognizer.requestCount() == 2 })
        #expect(await waitUntil { await harness.translator.requestCount() == 4 })

        await harness.session.refresh()
        #expect(await waitUntil { await harness.recognizer.requestCount() == 3 })

        await harness.session.stop()
    }

    @Test("Changing an explicit source language retranslates unchanged OCR blocks")
    func explicitSourceChangeInvalidatesTranslations() async throws {
        let harness = try makeHarness(sourceLanguage: .english)

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 1)

        await harness.session.setSourceLanguage(.japanese)

        #expect(await waitUntil { await harness.recognizer.requestCount() == 2 })
        #expect(await waitUntil { await harness.translator.requestCount() == 2 })

        await harness.session.stop()
    }

    @Test("An unchanged complete frame does not rerun OCR or translation")
    func ignoresUnchangedLiveFrame() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        let capturedAt = try #require(harness.viewModel.snapshot?.capturedAt) + 1
        await harness.frameSource.emit(
            CapturedRegionFrame(
                image: harness.image,
                capturedAt: capturedAt,
                dirtyRects: []
            )
        )
        try await Task<Never, Never>.sleep(nanoseconds: 650_000_000)

        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 1)

        await harness.session.stop()
    }

    @Test("An older callback in the same capture epoch cannot regress the accepted frame")
    func rejectsOutOfOrderFrameWithinCaptureEpoch() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        let initialCapturedAt = try #require(harness.viewModel.snapshot?.capturedAt)
        let newerCapturedAt = initialCapturedAt + 2
        let olderCapturedAt = initialCapturedAt + 1

        await harness.frameSource.emit(
            CapturedRegionFrame(
                image: harness.image,
                capturedAt: newerCapturedAt,
                dirtyRects: []
            )
        )
        #expect(await waitUntilScheduled {
            harness.viewModel.snapshot?.capturedAt == newerCapturedAt
        })
        let requestCountAfterNewerFrame = await harness.recognizer.requestCount()

        await harness.frameSource.emit(
            CapturedRegionFrame(
                image: harness.image,
                capturedAt: olderCapturedAt,
                dirtyRects: []
            )
        )
        await drainScheduledTasks()

        #expect(harness.viewModel.snapshot?.capturedAt == newerCapturedAt)
        #expect(await harness.recognizer.requestCount() == requestCountAfterNewerFrame)
        #expect(await harness.translator.requestCount() == 1)

        await harness.session.stop()
    }

    @Test("Stopping invalidates callbacks from a previously running frame source")
    func ignoresFramesAfterStop() async throws {
        let harness = try makeHarness()
        let changedImage = try #require(makeImage(gray: 1))

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        await harness.session.stop()
        await harness.frameSource.emit(
            CapturedRegionFrame(
                image: changedImage,
                capturedAt: 20,
                dirtyRects: [CGRect(x: 0, y: 0, width: 1, height: 1)]
            )
        )
        try await Task<Never, Never>.sleep(nanoseconds: 650_000_000)

        #expect(harness.viewModel.lifecycle == .stopped)
        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 1)
    }

    @Test("Permission loss stops retrying and publishes a recoverable capture state")
    func publishesPermissionFailure() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        await harness.frameSource.fail(.permissionDenied)
        #expect(await waitUntil { harness.viewModel.captureAvailability == .permissionDenied })

        #expect(
            harness.viewModel.processingState ==
                .recoverableError(generation: nil, category: .permission)
        )
        #expect(await harness.frameSource.metrics().startCount == 1)

        await harness.session.stop()
    }

    @Test("Permission loss during OCR rejects the delayed OCR and provider work")
    func rejectsInFlightOCRAfterPermissionLoss() async throws {
        let ocrBarrier = SessionTestBarrier()
        let harness = try makeHarness(ocrBarriers: [1: ocrBarrier])

        await harness.session.start()
        await ocrBarrier.waitForArrival()
        await harness.frameSource.fail(.permissionDenied)
        #expect(await waitUntilScheduled {
            harness.viewModel.processingState == .recoverableError(
                generation: nil,
                category: .permission
            ) && harness.viewModel.captureAvailability == .permissionDenied
        })

        await ocrBarrier.release()
        await drainScheduledTasks()

        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 0)
        #expect(harness.viewModel.snapshot?.translatedBlockCount ?? 0 == 0)
        #expect(
            harness.viewModel.processingState == .recoverableError(
                generation: nil,
                category: .permission
            )
        )
        #expect(harness.viewModel.captureAvailability == .permissionDenied)

        await harness.session.stop()
    }

    @Test("Display loss during provider translation rejects its delayed result")
    func rejectsInFlightProviderAfterDisplayLoss() async throws {
        let providerBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            translationBarriers: ["provider-a": [1: providerBarrier]]
        )

        await harness.session.start()
        await providerBarrier.waitForArrival()
        await harness.frameSource.fail(.displayUnavailable)
        #expect(await waitUntilScheduled {
            harness.viewModel.processingState == .recoverableError(
                generation: nil,
                category: .displayDisconnected
            ) && harness.viewModel.captureAvailability == .displayDisconnected
        })

        await providerBarrier.release()
        await drainScheduledTasks()

        #expect(await harness.translator.requestCount() == 1)
        #expect(
            harness.viewModel.snapshot?.blocks.contains {
                $0.providerIdentifier == "provider-a" && $0.status == .translated
            } == false
        )
        #expect(
            harness.viewModel.processingState == .recoverableError(
                generation: nil,
                category: .displayDisconnected
            )
        )
        #expect(harness.viewModel.captureAvailability == .displayDisconnected)

        await harness.session.stop()
    }

    @Test("Repeated stream stops receive only one automatic recovery attempt")
    func limitsAutomaticStreamRecovery() async throws {
        let harness = try makeHarness()

        await harness.session.start()
        #expect(await waitUntil { isReady(harness.viewModel.processingState) })
        await harness.frameSource.fail(.streamStopped)
        #expect(await waitUntil { await harness.frameSource.metrics().startCount == 2 })

        await harness.frameSource.fail(.streamStopped)
        try await Task<Never, Never>.sleep(nanoseconds: 650_000_000)

        #expect(await harness.frameSource.metrics().startCount == 2)

        await harness.session.stop()
    }

    @Test("A delayed capture start cannot revive callbacks after the session stops")
    func rejectsCallbacksFromDelayedCaptureStart() async throws {
        let startBarrier = SessionTestBarrier()
        let frameSource = SessionFrameSource(firstStartBarrier: startBarrier)
        let harness = try makeHarness(frameSource: frameSource)
        let changedImage = try #require(makeImage(gray: 1))
        let startTask = Task { await harness.session.start() }

        await startBarrier.waitForArrival()
        await harness.session.stop()
        await startBarrier.release()
        await startTask.value
        let requestCountAfterStop = await harness.recognizer.requestCount()

        await frameSource.emit(
            CapturedRegionFrame(
                image: changedImage,
                capturedAt: 20,
                dirtyRects: [CGRect(x: 0, y: 0, width: 1, height: 1)]
            ),
            fromStart: 0
        )
        await frameSource.fail(.permissionDenied, fromStart: 0)
        await drainScheduledTasks()

        #expect(harness.viewModel.lifecycle == .stopped)
        #expect(harness.viewModel.processingState == .idle)
        #expect(harness.viewModel.captureAvailability == .available)
        #expect(await harness.recognizer.requestCount() == requestCountAfterStop)
        #expect(await frameSource.metrics().startCount == 1)
    }

    @Test("A stale OCR completion cannot call the provider or replace the new generation")
    func rejectsOCRCompletionAfterGenerationChange() async throws {
        let ocrBarrier = SessionTestBarrier()
        let harness = try makeHarness(ocrBarriers: [1: ocrBarrier])

        await harness.session.start()
        await ocrBarrier.waitForArrival()
        await harness.session.setSourceLanguage(.japanese)
        await drainScheduledTasks()
        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 0)

        await ocrBarrier.release()
        await harness.recognizer.waitForRequestCount(2)
        await harness.translator.waitForRequestCount(1)
        #expect(await waitUntilScheduled {
            isReady(harness.viewModel.processingState)
                && harness.viewModel.snapshot?.blocks.first?.status == .translated
        })
        let acceptedGeneration = try #require(harness.viewModel.snapshot?.generation)
        let acceptedState = harness.viewModel.processingState
        await drainScheduledTasks()

        #expect(await harness.recognizer.requestCount() == 2)
        #expect(await harness.translator.requestCount() == 1)
        #expect(harness.viewModel.snapshot?.generation == acceptedGeneration)
        #expect(harness.viewModel.processingState == acceptedState)

        await harness.session.stop()
    }

    @Test("Stopping during a provider await prevents queued requests and late publication")
    func rejectsProviderCompletionAfterStop() async throws {
        let providerBarrier = SessionTestBarrier()
        let layout = makeLayout([
            ("left", CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.08)),
            ("right", CGRect(x: 0.6, y: 0.1, width: 0.3, height: 0.08)),
        ])
        let harness = try makeHarness(
            layout: layout,
            translationBarriers: ["provider-a": [1: providerBarrier]]
        )

        await harness.session.start()
        await providerBarrier.waitForArrival()
        #expect(await harness.translator.requestCount() == 1)

        await harness.session.stop()
        await providerBarrier.release()
        await drainScheduledTasks()

        #expect(await harness.translator.requestCount() == 1)
        #expect(harness.viewModel.lifecycle == .stopped)
        #expect(harness.viewModel.processingState == .idle)
        #expect(harness.viewModel.snapshot?.translatedBlockCount == 0)
    }

    @Test("Rapid provider changes keep the newest provider and stop safely during await")
    func keepsLatestProviderAcrossRacingChangesAndStop() async throws {
        let providerBBarrier = SessionTestBarrier()
        let providerCCloseBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            translationBarriers: [
                "provider-b": [1: providerBBarrier],
                "provider-c": [2: providerCCloseBarrier],
            ]
        )

        await harness.session.start()
        await harness.translator.waitForRequest(serviceIdentifier: "provider-a", count: 1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })

        let providerBTask = Task {
            await harness.session.setServiceIdentifier("provider-b")
        }
        await providerBBarrier.waitForArrival()
        let providerCTask = Task {
            await harness.session.setServiceIdentifier("provider-c")
        }
        await harness.translator.waitForRequest(serviceIdentifier: "provider-c", count: 1)
        await providerCTask.value
        await providerBBarrier.release()
        await providerBTask.value

        #expect(await waitUntilScheduled {
            harness.viewModel.snapshot?.blocks.first?.providerIdentifier == "provider-c"
                && harness.viewModel.snapshot?.blocks.first?.status == .translated
        })
        #expect(harness.viewModel.snapshot?.blocks.first?.translatedText == "provider-c:hello")

        await harness.session.setTargetLanguage(.japanese)
        await providerCCloseBarrier.waitForArrival()
        #expect(await harness.translator.requestCount(serviceIdentifier: "provider-c") == 2)

        await harness.session.stop()
        await providerCCloseBarrier.release()
        await drainScheduledTasks()

        #expect(await harness.translator.requestCount(serviceIdentifier: "provider-b") == 1)
        #expect(await harness.translator.requestCount(serviceIdentifier: "provider-c") == 2)
        #expect(harness.viewModel.lifecycle == .stopped)
        #expect(harness.viewModel.processingState == .idle)
    }

    @Test("Rapid ViewModel provider changes keep the newest session configuration")
    func keepsLatestProviderFromViewModelCommands() async throws {
        let previousIdentifier = Defaults[.inPlaceTranslationServiceIdentifier]
        defer { Defaults[.inPlaceTranslationServiceIdentifier] = previousIdentifier }
        let providerBBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            translationBarriers: ["provider-b": [1: providerBBarrier]]
        )

        await harness.session.start()
        await harness.translator.waitForRequest(serviceIdentifier: "provider-a", count: 1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })

        harness.viewModel.setServiceIdentifier("provider-b")
        await providerBBarrier.waitForArrival()
        harness.viewModel.setServiceIdentifier("provider-c")
        await harness.translator.waitForRequest(serviceIdentifier: "provider-c", count: 1)
        #expect(await waitUntilScheduled {
            harness.viewModel.snapshot?.blocks.first?.providerIdentifier == "provider-c"
                && harness.viewModel.snapshot?.blocks.first?.status == .translated
        })

        await providerBBarrier.release()
        await drainScheduledTasks()

        #expect(harness.viewModel.configuration.serviceIdentifier == "provider-c")
        #expect(harness.viewModel.snapshot?.blocks.first?.providerIdentifier == "provider-c")
        #expect(harness.viewModel.snapshot?.blocks.first?.translatedText == "provider-c:hello")

        await harness.session.stop()
    }

    @Test("A provider switch during paused initial OCR resumes only the newest generation")
    func switchesProviderDuringPausedInitialOCR() async throws {
        let initialOCRBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            liveUpdatesEnabled: false,
            ocrBarriers: [1: initialOCRBarrier]
        )

        await harness.session.start()
        await initialOCRBarrier.waitForArrival()
        #expect(harness.viewModel.lifecycle == .paused)

        await harness.session.setServiceIdentifier("provider-b")
        await drainScheduledTasks()
        #expect(await harness.recognizer.requestCount() == 1)
        #expect(await harness.translator.requestCount() == 0)

        await initialOCRBarrier.release()
        await harness.recognizer.waitForRequestCount(2)
        await harness.translator.waitForRequest(serviceIdentifier: "provider-b", count: 1)
        #expect(await waitUntilScheduled {
            isReady(harness.viewModel.processingState)
                && harness.viewModel.snapshot?.blocks.first?.providerIdentifier == "provider-b"
        })
        #expect(harness.viewModel.lifecycle == .paused)
        #expect(harness.viewModel.snapshot?.blocks.first?.translatedText == "provider-b:hello")

        await harness.session.stop()
    }

    @Test("Removing every service clears selection and rejects the old provider completion")
    func clearsProviderWhenNoServiceRemains() async throws {
        let previousIdentifier = Defaults[.inPlaceTranslationServiceIdentifier]
        defer { Defaults[.inPlaceTranslationServiceIdentifier] = previousIdentifier }
        let providerBarrier = SessionTestBarrier()
        let resolver = SessionServiceResolver()
        let harness = try makeHarness(
            serviceResolver: resolver,
            translationBarriers: ["provider-a": [1: providerBarrier]]
        )

        await harness.session.start()
        await providerBarrier.waitForArrival()
        let initialGeneration = try #require(harness.viewModel.snapshot?.generation)

        resolver.availableOptions = []
        harness.viewModel.refreshServiceMetadata()
        #expect(harness.viewModel.configuration.serviceIdentifier.isEmpty)
        #expect(harness.viewModel.serviceOptions.isEmpty)
        #expect(harness.viewModel.availableTargetLanguages.isEmpty)
        #expect(await waitUntilScheduled {
            guard let snapshot = harness.viewModel.snapshot else { return false }
            return snapshot.generation > initialGeneration
                && snapshot.blocks.allSatisfy { $0.providerIdentifier.isEmpty }
        })

        await providerBarrier.release()
        await drainScheduledTasks()

        #expect(await harness.translator.requestCount(serviceIdentifier: "provider-a") == 1)
        #expect(
            harness.viewModel.snapshot?.blocks.contains {
                $0.providerIdentifier == "provider-a" && $0.status == .translated
            } == false
        )

        await harness.session.stop()
    }

    @Test("Returning to the committed baseline clears an older changed candidate")
    func clearsCandidateWhenFrameReturnsToBaseline() async throws {
        let harness = try makeHarness()
        let changedImage = try #require(makeImage(gray: 1))
        let laterImage = try #require(makeImage(gray: 0.5))

        await harness.session.start()
        await harness.translator.waitForRequestCount(1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })
        let initialCapturedAt = try #require(harness.viewModel.snapshot?.capturedAt)

        await harness.frameSource.emit(
            frame(image: changedImage, capturedAt: initialCapturedAt + 1)
        )
        #expect(await waitUntilScheduled { harness.viewModel.processingState == .debouncing })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: initialCapturedAt + 2)
        )
        #expect(await waitUntilScheduled {
            harness.viewModel.snapshot?.capturedAt == initialCapturedAt + 2
        })

        await harness.frameSource.emit(
            frame(image: laterImage, capturedAt: initialCapturedAt + 100)
        )
        await drainScheduledTasks()

        #expect(await harness.recognizer.requestCount() == 1)
        await harness.session.stop()
    }

    @Test("Returning to the in-flight signature clears an older changed candidate")
    func clearsCandidateWhenFrameReturnsToInFlightSignature() async throws {
        let inFlightBarrier = SessionTestBarrier()
        let harness = try makeHarness(ocrBarriers: [2: inFlightBarrier])
        let changedImage = try #require(makeImage(gray: 1))
        let laterImage = try #require(makeImage(gray: 0.5))

        await harness.session.start()
        await harness.translator.waitForRequestCount(1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })
        let initialCapturedAt = try #require(harness.viewModel.snapshot?.capturedAt)

        await harness.session.setSourceLanguage(.japanese)
        await inFlightBarrier.waitForArrival()
        await harness.frameSource.emit(
            frame(image: changedImage, capturedAt: initialCapturedAt + 1)
        )
        #expect(await waitUntilScheduled { harness.viewModel.processingState == .debouncing })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: initialCapturedAt + 2)
        )
        await drainScheduledTasks()
        await harness.frameSource.emit(
            frame(image: laterImage, capturedAt: initialCapturedAt + 100)
        )
        await drainScheduledTasks()

        await inFlightBarrier.release()
        await harness.translator.waitForRequestCount(2)
        await drainScheduledTasks()

        #expect(await harness.recognizer.requestCount() == 2)
        await harness.session.stop()
    }

    @Test("A failed OCR signature suppresses only the current request and remains retryable")
    func retriesSameFrameAfterOCRFailure() async throws {
        let ocrBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            ocrBarriers: [1: ocrBarrier],
            ocrBehaviors: [1: .failure]
        )
        let capturedAt = ProcessInfo.processInfo.systemUptime + 10
        let sameFrame = CapturedRegionFrame(
            image: harness.image,
            capturedAt: capturedAt,
            dirtyRects: []
        )

        await harness.session.start()
        await ocrBarrier.waitForArrival()
        await harness.frameSource.emit(sameFrame)
        await drainScheduledTasks()
        #expect(await harness.recognizer.requestCount() == 1)

        await ocrBarrier.release()
        #expect(await waitUntilScheduled {
            if case .recoverableError = harness.viewModel.processingState {
                return true
            }
            return false
        })

        await harness.frameSource.emit(
            CapturedRegionFrame(
                image: harness.image,
                capturedAt: capturedAt + 1,
                dirtyRects: []
            )
        )
        await harness.recognizer.waitForRequestCount(2)
        await harness.translator.waitForRequestCount(1)

        #expect(await harness.recognizer.requestCount() == 2)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })

        await harness.session.stop()
    }

    @Test("A generic OCR failure retries one matching signature without entering a storm")
    func limitsGenericOCRRetriesForOneSignature() async throws {
        let firstBarrier = SessionTestBarrier()
        let secondBarrier = SessionTestBarrier()
        let refreshBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            ocrBarriers: [1: firstBarrier, 2: secondBarrier, 3: refreshBarrier],
            ocrBehaviors: [1: .failure, 2: .failure]
        )
        let capturedAt = ProcessInfo.processInfo.systemUptime + 10

        await harness.session.start()
        await firstBarrier.waitForArrival()
        await firstBarrier.release()
        #expect(await waitUntilScheduled {
            if case .recoverableError = harness.viewModel.processingState {
                return true
            }
            return false
        })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: capturedAt)
        )
        await secondBarrier.waitForArrival()
        let retryGeneration = try #require(
            recognizingGeneration(harness.viewModel.processingState)
        )
        await secondBarrier.release()
        #expect(await waitUntilScheduled {
            harness.viewModel.processingState == .recoverableError(
                generation: retryGeneration,
                category: .unknown
            )
        })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: capturedAt + 1)
        )
        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: capturedAt + 2)
        )
        await drainScheduledTasks()

        #expect(await harness.recognizer.requestCount() == 2)
        #expect(await harness.translator.requestCount() == 0)

        await harness.session.refresh()
        await refreshBarrier.waitForArrival()
        #expect(await harness.recognizer.requestCount() == 3)
        await refreshBarrier.release()
        await harness.translator.waitForRequestCount(1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })

        await harness.session.stop()
    }

    @Test("A baseline refresh failure gets one live retry before explicit refresh resets it")
    func retriesFailedRefreshAgainstCommittedBaselineOnce() async throws {
        let refreshFailureBarrier = SessionTestBarrier()
        let liveRetryFailureBarrier = SessionTestBarrier()
        let explicitRefreshBarrier = SessionTestBarrier()
        let harness = try makeHarness(
            ocrBarriers: [
                2: refreshFailureBarrier,
                3: liveRetryFailureBarrier,
                4: explicitRefreshBarrier,
            ],
            ocrBehaviors: [2: .failure, 3: .failure]
        )

        await harness.session.start()
        await harness.translator.waitForRequestCount(1)
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })
        let initialCapturedAt = try #require(harness.viewModel.snapshot?.capturedAt)

        await harness.session.refresh()
        await refreshFailureBarrier.waitForArrival()
        await refreshFailureBarrier.release()
        #expect(await waitUntilScheduled {
            if case .recoverableError = harness.viewModel.processingState {
                return true
            }
            return false
        })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: initialCapturedAt + 1)
        )
        await liveRetryFailureBarrier.waitForArrival()
        #expect(await harness.recognizer.requestCount() == 3)
        let retryGeneration = try #require(
            recognizingGeneration(harness.viewModel.processingState)
        )
        await liveRetryFailureBarrier.release()
        #expect(await waitUntilScheduled {
            harness.viewModel.processingState == .recoverableError(
                generation: retryGeneration,
                category: .unknown
            )
        })

        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: initialCapturedAt + 2)
        )
        await harness.frameSource.emit(
            frame(image: harness.image, capturedAt: initialCapturedAt + 3)
        )
        await drainScheduledTasks()
        #expect(await harness.recognizer.requestCount() == 3)

        await harness.session.refresh()
        await explicitRefreshBarrier.waitForArrival()
        #expect(await harness.recognizer.requestCount() == 4)
        await explicitRefreshBarrier.release()
        #expect(await waitUntilScheduled { isReady(harness.viewModel.processingState) })

        await harness.session.stop()
    }

    // MARK: Private

    /// Fully in-memory session dependencies used by one behavior test.
    private struct Harness {
        let image: CGImage
        let recognizer: SessionOCRRecognizer
        let translator: SessionBlockTranslator
        let frameSource: SessionFrameSource
        let viewModel: InPlaceTranslationViewModel
        let session: InPlaceTranslationSession
    }

    private func makeHarness(
        sourceLanguage: Language = .auto,
        liveUpdatesEnabled: Bool = true,
        layout: AppleOCRLayoutResult? = nil,
        frameSource providedFrameSource: SessionFrameSource? = nil,
        serviceResolver: any InPlaceTranslationServiceResolving = SessionServiceResolver(),
        ocrBarriers: [Int: SessionTestBarrier] = [:],
        ocrBehaviors: [Int: SessionOCRRecognizer.Behavior] = [:],
        translationBarriers: [String: [Int: SessionTestBarrier]] = [:]
    ) throws
        -> Harness {
        let image = try #require(makeImage(gray: 0))
        let layout = layout ?? makeLayout([
            ("hello", CGRect(x: 0.1, y: 0.1, width: 0.6, height: 0.1)),
        ])
        let recognizer = SessionOCRRecognizer(
            result: layout,
            barriers: ocrBarriers,
            behaviors: ocrBehaviors
        )
        let translator = SessionBlockTranslator(
            requestBarriers: translationBarriers
        )
        let frameSource = providedFrameSource ?? SessionFrameSource()
        let viewModel = InPlaceTranslationViewModel(
            configuration: InPlaceTranslationConfiguration(
                sourceLanguage: sourceLanguage,
                targetLanguage: .simplifiedChinese,
                serviceIdentifier: "provider-a",
                liveUpdatesEnabled: liveUpdatesEnabled,
                isPinned: true,
                renderMode: .translated
            ),
            serviceResolver: serviceResolver
        )
        let selection = ScreenshotSelection(
            displayID: 1,
            screenFrameInGlobalPoints: CGRect(x: 0, y: 0, width: 1_000, height: 800),
            sourceRectInDisplayPoints: CGRect(x: 100, y: 100, width: 400, height: 200),
            backingScaleFactor: 2,
            initialImage: NSImage(cgImage: image, size: NSSize(width: 400, height: 200))
        )
        let session = InPlaceTranslationSession(
            selection: selection,
            configuration: viewModel.configuration,
            viewModel: viewModel,
            frameSource: frameSource,
            ocrPipeline: InPlaceOCRPipeline(recognizer: recognizer),
            translationCoordinator: InPlaceTranslationCoordinator(
                translator: translator,
                maximumConcurrency: 1,
                retryDelay: 0
            )
        )
        viewModel.attach(session: session)
        return Harness(
            image: image,
            recognizer: recognizer,
            translator: translator,
            frameSource: frameSource,
            viewModel: viewModel,
            session: session
        )
    }

    private func makeLayout(
        _ entries: [(text: String, rect: CGRect)]
    )
        -> AppleOCRLayoutResult {
        let observations = entries.map { entry in
            AppleOCRLayoutObservation(
                id: UUID(),
                text: entry.text,
                confidence: 1,
                topLeft: CGPoint(x: entry.rect.minX, y: 1 - entry.rect.minY),
                topRight: CGPoint(x: entry.rect.maxX, y: 1 - entry.rect.minY),
                bottomRight: CGPoint(x: entry.rect.maxX, y: 1 - entry.rect.maxY),
                bottomLeft: CGPoint(x: entry.rect.minX, y: 1 - entry.rect.maxY)
            )
        }
        return AppleOCRLayoutResult(
            mergedText: observations.map(\.text).joined(separator: "\n"),
            detectedLanguage: .english,
            confidence: 1,
            observations: observations
        )
    }

    private func waitUntil(
        attempts: Int = 200,
        predicate: @escaping () async -> Bool
    ) async
        -> Bool {
        for _ in 0 ..< attempts {
            if await predicate() {
                return true
            }
            try? await Task<Never, Never>.sleep(nanoseconds: 10_000_000)
        }
        return await predicate()
    }

    private func waitUntilScheduled(
        attempts: Int = 2_000,
        predicate: @escaping () async -> Bool
    ) async
        -> Bool {
        for _ in 0 ..< attempts {
            if await predicate() {
                return true
            }
            await Task.yield()
        }
        return await predicate()
    }

    private func drainScheduledTasks(iterations: Int = 100) async {
        for _ in 0 ..< iterations {
            await Task.yield()
        }
    }

    private func isReady(_ state: InPlaceTranslationProcessingState) -> Bool {
        if case .ready = state {
            return true
        }
        return false
    }

    private func recognizingGeneration(
        _ state: InPlaceTranslationProcessingState
    )
        -> UInt64? {
        guard case let .recognizing(generation) = state else { return nil }
        return generation
    }

    private func frame(image: CGImage, capturedAt: TimeInterval) -> CapturedRegionFrame {
        CapturedRegionFrame(
            image: image,
            capturedAt: capturedAt,
            dirtyRects: [CGRect(x: 0, y: 0, width: 1, height: 1)]
        )
    }

    private func makeImage(gray: CGFloat) -> CGImage? {
        guard let context = CGContext(
            data: nil,
            width: 8,
            height: 8,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        return context.makeImage()
    }
}

// MARK: - SessionServiceResolver

/// Keeps session tests independent from the user's configured provider inventory.
private final class SessionServiceResolver: InPlaceTranslationServiceResolving {
    var availableOptions = [
        InPlaceTranslationServiceOption(identifier: "provider-a", displayName: "Provider A"),
        InPlaceTranslationServiceOption(identifier: "provider-b", displayName: "Provider B"),
        InPlaceTranslationServiceOption(identifier: "provider-c", displayName: "Provider C"),
    ]

    func options() -> [InPlaceTranslationServiceOption] {
        availableOptions
    }

    func resolveSelection(
        _ storedIdentifier: String,
        availableOptions: [InPlaceTranslationServiceOption]
    )
        -> InPlaceTranslationServiceResolution {
        if availableOptions.contains(where: { $0.identifier == storedIdentifier }) {
            return InPlaceTranslationServiceResolution(
                identifier: storedIdentifier,
                shouldResetStoredSelection: false
            )
        }
        return InPlaceTranslationServiceResolution(
            identifier: availableOptions.first?.identifier,
            shouldResetStoredSelection: true
        )
    }

    func supportedLanguages(identifier _: String) -> [Language] {
        [.english, .simplifiedChinese, .japanese]
    }
}

// MARK: - SessionTestBarrier

/// Suspends one fake dependency call until the test has changed lifecycle or generation.
private actor SessionTestBarrier {
    // MARK: Internal

    func arriveAndWait() async {
        hasArrived = true
        arrivalContinuation?.resume()
        arrivalContinuation = nil
        guard !isReleased else { return }
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitForArrival() async {
        guard !hasArrived else { return }
        await withCheckedContinuation { continuation in
            arrivalContinuation = continuation
        }
    }

    func release() {
        isReleased = true
        releaseContinuation?.resume()
        releaseContinuation = nil
    }

    // MARK: Private

    private var hasArrived = false
    private var isReleased = false
    private var arrivalContinuation: CheckedContinuation<(), Never>?
    private var releaseContinuation: CheckedContinuation<(), Never>?
}

// MARK: - SessionFrameSource

/// Stores capture callbacks so tests can emit frames and failures without ScreenCaptureKit.
private actor SessionFrameSource: RegionFrameSource {
    // MARK: Lifecycle

    init(firstStartBarrier: SessionTestBarrier? = nil) {
        self.firstStartBarrier = firstStartBarrier
    }

    // MARK: Internal

    /// Capture lifecycle counters that are safe to inspect outside the actor.
    struct Metrics: Sendable {
        let startCount: Int
        let stopCount: Int
    }

    func start(
        onFrame: @escaping @Sendable (CapturedRegionFrame) -> (),
        onFailure: @escaping @Sendable (RegionFrameSourceError) -> ()
    ) async throws {
        startCount += 1
        frameHandlers.append(onFrame)
        failureHandlers.append(onFailure)
        if startCount == 1, let firstStartBarrier {
            await firstStartBarrier.arriveAndWait()
        }
    }

    func stop() async {
        stopCount += 1
    }

    func emit(_ frame: CapturedRegionFrame, fromStart index: Int? = nil) {
        guard !frameHandlers.isEmpty else { return }
        let index = index ?? frameHandlers.index(before: frameHandlers.endIndex)
        guard frameHandlers.indices.contains(index) else { return }
        frameHandlers[index](frame)
    }

    func fail(_ error: RegionFrameSourceError, fromStart index: Int? = nil) {
        guard !failureHandlers.isEmpty else { return }
        let index = index ?? failureHandlers.index(before: failureHandlers.endIndex)
        guard failureHandlers.indices.contains(index) else { return }
        failureHandlers[index](error)
    }

    func metrics() -> Metrics {
        Metrics(startCount: startCount, stopCount: stopCount)
    }

    // MARK: Private

    private let firstStartBarrier: SessionTestBarrier?
    private var frameHandlers: [@Sendable (CapturedRegionFrame) -> ()] = []
    private var failureHandlers: [@Sendable (RegionFrameSourceError) -> ()] = []
    private var startCount = 0
    private var stopCount = 0
}

// MARK: - SessionOCRRecognizer

/// Returns a deterministic layout while recording how often and with which language OCR ran.
private actor SessionOCRRecognizer: OCRLayoutRecognizing {
    // MARK: Lifecycle

    init(
        result: AppleOCRLayoutResult,
        barriers: [Int: SessionTestBarrier] = [:],
        behaviors: [Int: Behavior] = [:]
    ) {
        self.result = result
        self.barriers = barriers
        self.behaviors = behaviors
    }

    // MARK: Internal

    /// Deterministic completion selected by one-based OCR request index.
    enum Behavior: Equatable, Sendable {
        case success
        case failure
    }

    func recognizeLayout(image _: CGImage, language: Language) async throws -> AppleOCRLayoutResult {
        languages.append(language)
        let requestIndex = languages.count
        resumeRequestWaiters()
        if let barrier = barriers[requestIndex] {
            await barrier.arriveAndWait()
        }
        if behaviors[requestIndex] == .failure {
            throw SessionOCRTestError.failure
        }
        return result
    }

    func requestCount() -> Int {
        languages.count
    }

    func waitForRequestCount(_ count: Int) async {
        guard languages.count < count else { return }
        await withCheckedContinuation { continuation in
            requestWaiters.append(
                RequestWaiter(count: count, continuation: continuation)
            )
        }
    }

    // MARK: Private

    /// One suspended assertion waiting for a deterministic request count.
    private struct RequestWaiter {
        let count: Int
        let continuation: CheckedContinuation<(), Never>
    }

    private let result: AppleOCRLayoutResult
    private let barriers: [Int: SessionTestBarrier]
    private let behaviors: [Int: Behavior]
    private var languages: [Language] = []
    private var requestWaiters: [RequestWaiter] = []

    private func resumeRequestWaiters() {
        let ready = requestWaiters.filter { languages.count >= $0.count }
        requestWaiters.removeAll { languages.count >= $0.count }
        for waiter in ready {
            waiter.continuation.resume()
        }
    }
}

// MARK: - SessionOCRTestError

/// Content-free OCR failure used to verify signature retry behavior.
private enum SessionOCRTestError: Error {
    case failure
}

// MARK: - SessionBlockTranslator

/// Records block requests and returns deterministic text without a provider or network.
private actor SessionBlockTranslator: InPlaceBlockTranslating {
    // MARK: Lifecycle

    init(requestBarriers: [String: [Int: SessionTestBarrier]] = [:]) {
        self.requestBarriers = requestBarriers
    }

    // MARK: Internal

    /// One provider call recorded before any configured barrier suspends it.
    struct Request: Sendable {
        let text: String
        let serviceIdentifier: String
    }

    func translate(
        text: String,
        sourceLanguage _: Language,
        targetLanguage _: Language,
        serviceIdentifier: String
    ) async throws
        -> String {
        requests.append(Request(text: text, serviceIdentifier: serviceIdentifier))
        let occurrence = requestCount(serviceIdentifier: serviceIdentifier)
        resumeRequestWaiters()
        if let barrier = requestBarriers[serviceIdentifier]?[occurrence] {
            await barrier.arriveAndWait()
        }
        return "\(serviceIdentifier):\(text)"
    }

    func requestCount() -> Int {
        requests.count
    }

    func requestCount(serviceIdentifier: String) -> Int {
        requests.count { $0.serviceIdentifier == serviceIdentifier }
    }

    func waitForRequestCount(_ count: Int) async {
        await waitForRequest(serviceIdentifier: nil, count: count)
    }

    func waitForRequest(serviceIdentifier: String, count: Int) async {
        await waitForRequest(serviceIdentifier: Optional(serviceIdentifier), count: count)
    }

    // MARK: Private

    /// One suspended assertion waiting for a deterministic provider request count.
    private struct RequestWaiter {
        let serviceIdentifier: String?
        let count: Int
        let continuation: CheckedContinuation<(), Never>
    }

    private let requestBarriers: [String: [Int: SessionTestBarrier]]
    private var requests: [Request] = []
    private var requestWaiters: [RequestWaiter] = []

    private func waitForRequest(serviceIdentifier: String?, count: Int) async {
        guard currentRequestCount(serviceIdentifier: serviceIdentifier) < count else { return }
        await withCheckedContinuation { continuation in
            requestWaiters.append(
                RequestWaiter(
                    serviceIdentifier: serviceIdentifier,
                    count: count,
                    continuation: continuation
                )
            )
        }
    }

    private func currentRequestCount(serviceIdentifier: String?) -> Int {
        guard let serviceIdentifier else { return requests.count }
        return requestCount(serviceIdentifier: serviceIdentifier)
    }

    private func resumeRequestWaiters() {
        let ready = requestWaiters.filter {
            currentRequestCount(serviceIdentifier: $0.serviceIdentifier) >= $0.count
        }
        requestWaiters.removeAll {
            currentRequestCount(serviceIdentifier: $0.serviceIdentifier) >= $0.count
        }
        for waiter in ready {
            waiter.continuation.resume()
        }
    }
}
