#!/usr/bin/env node

"use strict";

const fs = require("fs");
const path = require("path");

const MINIMUM_FRAME_COUNT = 55;
const EMPTY_OPENING_FRAME = 0;
const RESET_OPACITY_SAMPLES = Object.freeze([1.00, 0.7575, 0.515, 0.2725, 0.03]);
const STYLE_1_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "ingress", order: 0, start: 1, end: 8 }),
  Object.freeze({ role: "reason", order: 0, start: 5, end: 12 }),
  Object.freeze({ role: "extract", order: 0, start: 9, end: 16 }),
  Object.freeze({ role: "transform", order: 0, start: 13, end: 20 }),
  Object.freeze({ role: "resolve", order: 1, start: 17, end: 24 }),
  Object.freeze({ role: "memory-write", order: 0, start: 21, end: 28 }),
  Object.freeze({ role: "memory-read", order: 0, start: 25, end: 32 }),
  Object.freeze({ role: "response-context", order: 0, start: 29, end: 36 }),
]);
const STYLE_2_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "ingress", stage: 1, order: 0, start: 1, end: 8 }),
  Object.freeze({ role: "delegate", stage: 2, order: 0, start: 5, end: 12 }),
  Object.freeze({ role: "tool-call", stage: 3, order: 0, start: 9, end: 16 }),
  Object.freeze({ role: "inspect", stage: 4, order: 0, start: 13, end: 20 }),
  Object.freeze({ role: "index", stage: 5, order: 0, start: 17, end: 24 }),
  Object.freeze({ role: "grounding", stage: 6, order: 0, start: 21, end: 28 }),
  Object.freeze({ role: "grounding", stage: 6, order: 1, start: 25, end: 32 }),
  Object.freeze({ role: "answer", stage: 7, order: 0, start: 29, end: 36 }),
]);
const STYLE_3_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "ingress", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "policy", stage: 2, order: 0, start: 4, end: 9 }),
  Object.freeze({ role: "fanout", stage: 3, order: 0, start: 8, end: 13 }),
  Object.freeze({ role: "fanout", stage: 3, order: 1, start: 11, end: 16 }),
  Object.freeze({ role: "fanout", stage: 3, order: 2, start: 14, end: 19 }),
  Object.freeze({ role: "data-write", stage: 4, order: 0, start: 18, end: 23 }),
  Object.freeze({ role: "data-write", stage: 4, order: 1, start: 21, end: 26 }),
  Object.freeze({ role: "data-write", stage: 4, order: 2, start: 24, end: 29 }),
  Object.freeze({ role: "event", stage: 5, order: 0, start: 28, end: 33 }),
  Object.freeze({ role: "telemetry", stage: 6, order: 0, start: 31, end: 36 }),
]);
const STYLE_4_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "sample", stage: 1, order: 0, start: 1, end: 4 }),
  Object.freeze({ role: "attend", stage: 2, order: 0, start: 5, end: 8 }),
  Object.freeze({ role: "invoke", stage: 3, order: 0, start: 9, end: 12 }),
  Object.freeze({ role: "remember", stage: 4, order: 0, start: 13, end: 22 }),
  Object.freeze({ role: "consolidate", stage: 5, order: 0, start: 23, end: 26 }),
  Object.freeze({ role: "recall", stage: 6, order: 0, start: 27, end: 36 }),
]);
const STYLE_5_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "ingress", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "delegate", stage: 2, order: 0, start: 5, end: 12 }),
  Object.freeze({ role: "delegate", stage: 2, order: 1, start: 8, end: 15 }),
  Object.freeze({ role: "delegate", stage: 2, order: 2, start: 11, end: 18 }),
  Object.freeze({ role: "evidence", stage: 3, order: 0, start: 17, end: 24 }),
  Object.freeze({ role: "artifact", stage: 3, order: 1, start: 20, end: 27 }),
  Object.freeze({ role: "context", stage: 4, order: 0, start: 25, end: 30 }),
  Object.freeze({ role: "deliver", stage: 5, order: 0, start: 29, end: 36 }),
  Object.freeze({ role: "approval", stage: 5, order: 1, start: 29, end: 36 }),
]);
const STYLE_6_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "ingress", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "dispatch", stage: 2, order: 0, start: 5, end: 12 }),
  Object.freeze({ role: "runtime-branch", stage: 3, order: 0, start: 10, end: 17 }),
  Object.freeze({ role: "runtime-branch", stage: 3, order: 1, start: 13, end: 20 }),
  Object.freeze({ role: "runtime-branch", stage: 3, order: 2, start: 16, end: 23 }),
  Object.freeze({ role: "foundation", stage: 4, order: 0, start: 21, end: 28 }),
  Object.freeze({ role: "foundation", stage: 4, order: 1, start: 24, end: 31 }),
  Object.freeze({ role: "foundation", stage: 4, order: 2, start: 27, end: 34 }),
  Object.freeze({ role: "promote", stage: 5, order: 0, start: 31, end: 36 }),
]);
const STYLE_7_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "connect", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "prepare", stage: 2, order: 0, start: 5, end: 12 }),
  Object.freeze({ role: "invoke", stage: 3, order: 0, start: 10, end: 17 }),
  Object.freeze({ role: "tool-call", stage: 4, order: 0, start: 15, end: 22 }),
  Object.freeze({ role: "token-stream", stage: 4, order: 1, start: 18, end: 27 }),
  Object.freeze({ role: "govern", stage: 5, order: 0, start: 25, end: 32 }),
  Object.freeze({ role: "measure", stage: 5, order: 1, start: 25, end: 32 }),
  Object.freeze({ role: "promote", stage: 6, order: 0, start: 31, end: 36 }),
]);
const STYLE_8_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "primary", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "primary", stage: 2, order: 0, start: 5, end: 10 }),
  Object.freeze({ role: "memory-read", stage: 3, order: 0, start: 9, end: 18 }),
  Object.freeze({ role: "tool-call", stage: 3, order: 1, start: 12, end: 21 }),
  Object.freeze({ role: "data", stage: 4, order: 0, start: 20, end: 25 }),
  Object.freeze({ role: "trace", stage: 5, order: 0, start: 24, end: 29 }),
  Object.freeze({ role: "feedback", stage: 6, order: 0, start: 28, end: 36 }),
]);
const STYLE_9_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "review-entry", stage: 1, order: 0, start: 1, end: 7 }),
  Object.freeze({ role: "review-request", stage: 2, order: 0, start: 7, end: 13 }),
  Object.freeze({ role: "review-async", stage: 3, order: 0, start: 13, end: 22 }),
  Object.freeze({ role: "review-state", stage: 4, order: 0, start: 22, end: 30 }),
  Object.freeze({ role: "review-external", stage: 4, order: 1, start: 28, end: 36 }),
]);
const STYLE_10_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "global-route", stage: 1, order: 0, start: 1, end: 12 }),
  Object.freeze({ role: "global-route", stage: 1, order: 1, start: 1, end: 12 }),
  Object.freeze({ role: "regional-write", stage: 2, order: 0, start: 13, end: 22 }),
  Object.freeze({ role: "regional-write", stage: 2, order: 1, start: 13, end: 22 }),
  Object.freeze({ role: "cross-region", stage: 3, order: 0, start: 23, end: 36 }),
]);
const STYLE_11_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "topic-rail", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "topic-rail", stage: 2, order: 0, start: 7, end: 12 }),
  Object.freeze({ role: "topic-rail", stage: 3, order: 0, start: 13, end: 18 }),
  Object.freeze({ role: "topic-rail", stage: 4, order: 0, start: 19, end: 24 }),
  Object.freeze({ role: "dead-letter", stage: 5, order: 0, start: 25, end: 32 }),
  Object.freeze({ role: "state-project", stage: 5, order: 1, start: 29, end: 36 }),
]);
const STYLE_12_DRAW_SCHEDULE = Object.freeze([
  Object.freeze({ role: "critical-request", stage: 1, order: 0, start: 1, end: 6 }),
  Object.freeze({ role: "critical-request", stage: 2, order: 0, start: 7, end: 12 }),
  Object.freeze({ role: "critical-request", stage: 3, order: 0, start: 13, end: 18 }),
  Object.freeze({ role: "telemetry-export", stage: 4, order: 0, start: 19, end: 26 }),
]);
const STYLE_1_STREAM_CONTRACT = Object.freeze({
  start: 36,
  fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
  bodyDashPattern: Object.freeze([16, 25]),
  headDashPattern: Object.freeze([6, 35]),
  dashPeriod: 41,
  dashOffsetPerFrame: -6.0,
  headLeadOffset: -10,
  bodyOpacity: 0.90,
  headOpacity: 0.98,
  headStrokeWidth: 2.20,
  bodyPrimitive: "persistent-data-flow-stream",
  headPrimitive: "persistent-data-flow-head",
  bodyColor: "#06b6d4",
  headColor: "#e0f2fe",
  bodyWidthMaximum: 4.0,
  bodyWidthMinimum: 3.0,
  bodyWidthMultiplier: 1.60,
  bodyWidthDescription: "min(4.0, max(3.0, source_stroke * 1.60))",
  sourceStrokeWidth: 2.4,
  resolvedStrokeWidth: 3.84,
  phaseStageMultiplier: 7,
  phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 41",
  expectedStreamPhases: Object.freeze([7, 14, 21, 28, 31, 35, 1, 8]),
  directionSentinels: Object.freeze([
    Object.freeze({ role: "ingress", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "resolve", order: 1, expected: Object.freeze(["left"]) }),
    Object.freeze({ role: "memory-write", order: 0, expected: Object.freeze(["down", "left", "down"]) }),
  ]),
  resetBehavior: "all eight body/head pairs keep advancing while topology, labels, and both flow layers fade together",
});
const STYLE_2_STREAM_CONTRACT = Object.freeze({
  start: 36,
  fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
  bodyDashPattern: Object.freeze([15, 26]),
  headDashPattern: Object.freeze([5, 36]),
  dashPeriod: 41,
  dashOffsetPerFrame: -6.0,
  headLeadOffset: -10,
  bodyOpacity: 0.94,
  headOpacity: 1.00,
  headStrokeWidth: 2.00,
  bodyPrimitive: "terminal-evidence-stream",
  headPrimitive: "terminal-command-head",
  bodyColor: "inherit-source-stroke",
  headColor: "#f8fafc",
  bodyWidthMaximum: 3.8,
  bodyWidthMinimum: 3.0,
  bodyWidthMultiplier: 1.50,
  bodyWidthPrecision: 2,
  bodyWidthDescription: "min(3.8, max(3.0, source_stroke * 1.50))",
  sourceStrokeWidth: 2.3,
  resolvedStrokeWidth: 3.45,
  phaseStageMultiplier: 6,
  phasePolicy: "(motionStage * 6 + motionOrder * 3) mod 41",
  expectedStreamPhases: Object.freeze([6, 12, 18, 24, 30, 36, 39, 1]),
  expectedSourceColors: Object.freeze([
    "#a855f7", "#a855f7", "#38bdf8", "#38bdf8",
    "#22c55e", "#fb7185", "#fb7185", "#f97316",
  ]),
  directionSentinels: Object.freeze([
    Object.freeze({ role: "ingress", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "delegate", order: 0, expected: Object.freeze(["down", "left", "down"]) }),
    Object.freeze({ role: "tool-call", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "inspect", order: 0, expected: Object.freeze(["down"]) }),
    Object.freeze({ role: "index", order: 0, expected: Object.freeze(["right", "up"]) }),
    Object.freeze({ role: "grounding", order: 0, expected: Object.freeze(["up", "left", "up"]) }),
    Object.freeze({ role: "grounding", order: 1, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "answer", order: 0, expected: Object.freeze(["right"]) }),
  ]),
  resetBehavior: "all eight body/head pairs keep advancing while topology, labels, cursor, and both flow layers fade together",
});
const STYLE_3_STREAM_CONTRACT = Object.freeze({
  start: 36,
  fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
  bodyDashPattern: Object.freeze([12, 31]),
  dashPeriod: 43,
  dashOffsetPerFrame: -6.0,
  beadAdvancePerFrame: 6.0,
  bodyOpacity: 0.92,
  beadOpacity: 0.98,
  beadRadius: 3.0,
  beadFill: "#e0f2fe",
  beadStrokeWidth: 1.2,
  bodyPrimitive: "blueprint-distribution-wave",
  beadPrimitive: "blueprint-registration-bead",
  bodyColor: "inherit-source-stroke",
  bodyWidthMaximum: 3.4,
  bodyWidthMinimum: 2.8,
  bodyWidthMultiplier: 1.40,
  bodyWidthPrecision: 2,
  bodyWidthDescription: "min(3.4, max(2.8, source_stroke * 1.40))",
  sourceStrokeWidth: 2.1,
  resolvedStrokeWidth: 2.94,
  phaseStageMultiplier: 7,
  phaseOrderMultiplier: 0,
  phasePolicy: "(motionStage * 7 + motionOrder * 0) mod 43",
  expectedStreamPhases: Object.freeze([7, 14, 21, 21, 21, 28, 28, 28, 35, 42]),
  expectedSourceColors: Object.freeze([
    "#38bdf8", "#67e8f9", "#38bdf8", "#38bdf8", "#38bdf8",
    "#fde047", "#fde047", "#fde047", "#fb7185", "#fb7185",
  ]),
  directionSentinels: Object.freeze([
    Object.freeze({ role: "ingress", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "policy", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "fanout", order: 0, expected: Object.freeze(["down", "left", "down"]) }),
    Object.freeze({ role: "fanout", order: 1, expected: Object.freeze(["down"]) }),
    Object.freeze({ role: "fanout", order: 2, expected: Object.freeze(["down", "right", "down"]) }),
    Object.freeze({ role: "data-write", order: 0, expected: Object.freeze(["down"]) }),
    Object.freeze({ role: "data-write", order: 1, expected: Object.freeze(["down"]) }),
    Object.freeze({ role: "data-write", order: 2, expected: Object.freeze(["down"]) }),
    Object.freeze({ role: "event", order: 0, expected: Object.freeze(["right"]) }),
    Object.freeze({ role: "telemetry", order: 0, expected: Object.freeze(["down"]) }),
  ]),
  resetBehavior: "all ten bodies and registration beads keep advancing while topology, labels, and both Blueprint flow layers fade together",
});
const STYLE_4_STREAM_CONTRACT = Object.freeze({
  start: 36,
  fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
  bodyDashPattern: Object.freeze([12, 35]),
  dashPeriod: 47,
  dashOffsetPerFrame: -6.0,
  cardAdvancePerFrame: 6.0,
  bodyOpacity: 0.88,
  cardOpacity: 0.98,
  bodyPrimitive: "notion-memory-rail",
  cardPrimitive: "notion-memory-card",
  bodyColor: "semantic-memory-destination",
  bodyWidthMaximum: 3.0,
  bodyWidthMinimum: 2.4,
  bodyWidthMultiplier: 1.50,
  bodyWidthPrecision: 2,
  bodyWidthDescription: "min(3.0, max(2.4, source_stroke * 1.50))",
  sourceStrokeWidth: 1.8,
  resolvedStrokeWidth: 2.70,
  phaseStageMultiplier: 7,
  phaseOrderMultiplier: 0,
  phasePolicy: "(motionStage * 7 + motionOrder * 0) mod 47",
  expectedStreamPhases: Object.freeze([7, 14, 21, 28, 35, 42]),
  expectedSourceColors: Object.freeze([
    "#3b82f6", "#3b82f6", "#3b82f6", "#3b82f6", "#3b82f6", "#3b82f6",
  ]),
  semanticColors: Object.freeze([
    "#3b82f6", "#3b82f6", "#7c3aed", "#059669", "#ea580c", "#ea580c",
  ]),
  initialNormalizedProgress: Object.freeze([0.08, 0.22, 0.36, 0.50, 0.64, 0.78]),
  endpointClearance: 8,
  outerRect: Object.freeze({ x: -7, y: -5, width: 14, height: 10, rx: 2 }),
  cardFill: "#ffffff",
  cardStrokeWidth: 1.4,
  inkStrokeWidth: 2.0,
  inkLinecap: "butt",
  inkShapeRendering: "crispEdges",
  inkLines: Object.freeze([
    Object.freeze({ x1: -4.5, y1: -2, x2: 4, y2: -2 }),
    Object.freeze({ x1: -4.5, y1: 2, x2: 0.5, y2: 2 }),
  ]),
  directionSentinels: Object.freeze([
    Object.freeze({ role: "sample", order: 0, expected: Object.freeze(["right"]), tangentRotation: 0 }),
    Object.freeze({ role: "attend", order: 0, expected: Object.freeze(["right"]), tangentRotation: 0 }),
    Object.freeze({ role: "invoke", order: 0, expected: Object.freeze(["right"]), tangentRotation: 0 }),
    Object.freeze({ role: "remember", order: 0, expected: Object.freeze(["down"]), tangentRotation: 90 }),
    Object.freeze({ role: "consolidate", order: 0, expected: Object.freeze(["right"]), tangentRotation: 0 }),
    Object.freeze({ role: "recall", order: 0, expected: Object.freeze(["up"]), tangentRotation: -90 }),
  ]),
  resetBehavior: "all six rails and six memory cards keep advancing while topology, labels, rails, and cards fade together",
});
const SPECIALIZED_STREAM_CONTRACTS = Object.freeze({
  5: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([13, 30]), dashPeriod: 43, dashOffsetPerFrame: -6,
    advancePerFrame: 6, bodyOpacity: 0.88, bodyPrimitive: "glass-handoff-rail",
    signaturePrimitive: "glass-task-capsule", signatureKind: "glass-task-capsule",
    bodyWidthMaximum: 2.2, bodyWidthDescription: "min(2.2, source_stroke)", endpointClearance: 8,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 43",
    expectedStreamPhases: Object.freeze([7, 14, 17, 20, 21, 24, 28, 35, 38]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "ingress", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "delegate", order: 0, expected: Object.freeze(["down", "left", "down"]) }),
      Object.freeze({ role: "delegate", order: 2, expected: Object.freeze(["down", "right", "down"]) }),
      Object.freeze({ role: "evidence", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "context", order: 0, expected: Object.freeze(["right"]) }),
    ]),
    auxiliary: Object.freeze({ kind: "node-halo", primitive: "coordinator-halo", nodeId: "coordinator", periodFrames: 16, minimumOpacity: 0.12, maximumOpacity: 0.32 }),
  }),
  6: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([11, 36]), dashPeriod: 47, dashOffsetPerFrame: -6,
    advancePerFrame: 6, bodyOpacity: 0.82, bodyPrimitive: "governance-thread",
    signaturePrimitive: "policy-seal", signatureKind: "policy-seal",
    bodyWidthMaximum: 2.8, bodyWidthDescription: "min(2.8, source_stroke)", endpointClearance: 8,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 47",
    expectedStreamPhases: Object.freeze([7, 14, 21, 24, 27, 28, 31, 34, 35]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "ingress", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "dispatch", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "runtime-branch", order: 0, expected: Object.freeze(["left"]) }),
      Object.freeze({ role: "runtime-branch", order: 1, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "foundation", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "promote", order: 0, expected: Object.freeze(["right"]) }),
    ]),
  }),
  7: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([10, 33]), dashPeriod: 43, dashOffsetPerFrame: -6,
    advancePerFrame: 6, bodyOpacity: 0.86, bodyPrimitive: "api-token-rail",
    signaturePrimitive: "token-train", signatureKind: "token-train",
    bodyWidthMaximum: 2.5, bodyWidthDescription: "min(2.5, source_stroke)", endpointClearance: 10,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 43",
    expectedStreamPhases: Object.freeze([7, 14, 21, 28, 31, 35, 38, 42]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "connect", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "prepare", order: 0, expected: Object.freeze(["down", "left", "down"]) }),
      Object.freeze({ role: "tool-call", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "token-stream", order: 1, expected: Object.freeze(["down", "left", "down"]) }),
      Object.freeze({ role: "govern", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "promote", order: 0, expected: Object.freeze(["right"]) }),
    ]),
  }),
  8: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([14, 33]), dashPeriod: 47, dashOffsetPerFrame: -6,
    advancePerFrame: 6, bodyOpacity: 0.86, bodyPrimitive: "luxury-circuit-rail",
    signaturePrimitive: "gem-tracer", signatureKind: "gem-tracer",
    bodyWidthMaximum: 2.8, bodyWidthDescription: "min(2.8, source_stroke)", endpointClearance: 8,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 47",
    expectedStreamPhases: Object.freeze([7, 14, 21, 24, 28, 35, 42]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "primary", stage: 1, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "primary", stage: 2, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "memory-read", stage: 3, order: 0, expected: Object.freeze(["down", "left", "down"]) }),
      Object.freeze({ role: "feedback", stage: 6, order: 0, expected: Object.freeze(["up", "left", "up"]) }),
    ]),
  }),
  9: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([8, 33]), dashPeriod: 41, dashOffsetPerFrame: -5,
    advancePerFrame: 5, bodyOpacity: 0.82, bodyPrimitive: "review-trace-rail",
    signaturePrimitive: "review-cursor", signatureKind: "review-cursor",
    bodyWidthMaximum: 2.6, bodyWidthDescription: "min(2.6, source_stroke)", endpointClearance: 9,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 7 + motionOrder * 3) mod 41",
    expectedStreamPhases: Object.freeze([7, 14, 21, 28, 31]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "review-entry", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "review-request", order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "review-async", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "review-state", order: 0, expected: Object.freeze(["left"]) }),
      Object.freeze({ role: "review-external", order: 1, expected: Object.freeze(["right"]) }),
    ]),
  }),
  10: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([12, 31]), dashPeriod: 43, dashOffsetPerFrame: -6,
    advancePerFrame: 6, bodyOpacity: 0.82, bodyPrimitive: "cloud-flow-rail",
    signaturePrimitive: "region-chevron-pair-or-replication-capsule", signatureKind: "cloud-flow",
    bodyWidthMaximum: 2.7, bodyWidthDescription: "min(2.7, source_stroke)", endpointClearance: 8,
    phaseStageMultiplier: 7, phaseOrderMultiplier: 0,
    phasePolicy: "motionStage * 7 mod 43; A/B orders are phase-locked",
    expectedStreamPhases: Object.freeze([7, 7, 14, 14, 21]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "global-route", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "global-route", order: 1, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "regional-write", order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "regional-write", order: 1, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "cross-region", order: 0, expected: Object.freeze(["right"]) }),
    ]),
    auxiliary: Object.freeze({ kind: "container-pair-pulse", primitive: "availability-pulse", containerIds: Object.freeze(["region-a", "region-b"]), periodFrames: 16, minimumOpacity: 0.10, maximumOpacity: 0.26 }),
  }),
  11: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([8, 33]), dashPeriod: 41, dashOffsetPerFrame: -5,
    advancePerFrame: 5, bodyOpacity: 0.78, bodyPrimitive: "event-transit-rail",
    signaturePrimitive: "event-train-or-branch-car", signatureKind: "event-transit",
    bodyWidthMaximum: 2.2, bodyWidthDescription: "min(2.2, source_stroke)", endpointClearance: 7,
    phaseStageMultiplier: 5, phaseOrderMultiplier: 3,
    phasePolicy: "(motionStage * 5 + motionOrder * 3) mod 41",
    expectedStreamPhases: Object.freeze([5, 10, 15, 20, 25, 28]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "topic-rail", stage: 1, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "topic-rail", stage: 2, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "topic-rail", stage: 3, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "topic-rail", stage: 4, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "dead-letter", stage: 5, order: 0, expected: Object.freeze(["down"]) }),
      Object.freeze({ role: "state-project", stage: 5, order: 1, expected: Object.freeze(["down"]) }),
    ]),
    auxiliary: Object.freeze({ kind: "station-dwell-rings", primitive: "station-dwell-ring", periodFrames: 10 }),
  }),
  12: Object.freeze({
    start: 36, fadeInFactors: Object.freeze([0.30, 0.65, 1.00]),
    bodyDashPattern: Object.freeze([12, 31]), dashPeriod: 43, dashOffsetPerFrame: -5,
    advancePerFrame: 5, bodyOpacity: 0.84, bodyPrimitive: "incident-pulse-rail-or-telemetry-export-rail",
    signaturePrimitive: "ecg-head-or-telemetry-export-packet", signatureKind: "ops-pulse",
    bodyWidthMaximum: 2.2, bodyWidthDescription: "min(2.2, source_stroke)", endpointClearance: 8,
    phaseStageMultiplier: 5, phaseOrderMultiplier: 0,
    phasePolicy: "motionStage * 5 mod 43",
    expectedStreamPhases: Object.freeze([5, 10, 15, 20]),
    directionSentinels: Object.freeze([
      Object.freeze({ role: "critical-request", stage: 1, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "critical-request", stage: 2, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "critical-request", stage: 3, order: 0, expected: Object.freeze(["right"]) }),
      Object.freeze({ role: "telemetry-export", stage: 4, order: 0, expected: Object.freeze(["down"]) }),
    ]),
    auxiliary: Object.freeze({ kind: "ops-pulse", primitive: "checkout-degraded-halo", nodeId: "checkout-service", periodFrames: 18, minimumOpacity: 0.10, maximumOpacity: 0.28 }),
  }),
});
const TERMINAL_CURSOR_CONTRACT = Object.freeze({
  primitive: "terminal-prompt-cursor",
  nodeId: "terminal",
  sourceText: "_",
  start: 16,
  periodFrames: 16,
  brightFrames: 8,
  absentFrames: 8,
  brightOpacity: 0.95,
  height: 2.2,
  fill: "#a7f3d0",
});
const SCENE_CONTRACTS = Object.freeze({
  "memory-weave": Object.freeze({
    styleId: 1,
    name: "Memory Weave",
    drawSchedule: STYLE_1_DRAW_SCHEDULE,
    stream: STYLE_1_STREAM_CONTRACT,
    signature: null,
    legacyStyleOneReport: true,
  }),
  "tool-grounding": Object.freeze({
    styleId: 2,
    name: "Dark Terminal",
    drawSchedule: STYLE_2_DRAW_SCHEDULE,
    stream: STYLE_2_STREAM_CONTRACT,
    signature: TERMINAL_CURSOR_CONTRACT,
    legacyStyleOneReport: false,
  }),
  "service-blueprint": Object.freeze({
    styleId: 3,
    name: "Blueprint",
    drawSchedule: STYLE_3_DRAW_SCHEDULE,
    stream: STYLE_3_STREAM_CONTRACT,
    signature: null,
    legacyStyleOneReport: false,
    streamMode: "blueprint-registration-bead",
    expectedRouteLabelCount: 7,
    requiresLabelPerEdge: false,
    requiredMaximumConcurrentDraws: 2,
  }),
  "memory-lifecycle": Object.freeze({
    styleId: 4,
    name: "Notion Clean",
    drawSchedule: STYLE_4_DRAW_SCHEDULE,
    stream: STYLE_4_STREAM_CONTRACT,
    signature: null,
    legacyStyleOneReport: false,
    streamMode: "notion-memory-card-handoff",
    expectedRouteLabelCount: 2,
    requiresLabelPerEdge: false,
    requiredMaximumConcurrentDraws: 1,
  }),
  "agent-orchestration": Object.freeze({
    styleId: 5, name: "Glassmorphism", drawSchedule: STYLE_5_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[5], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 9,
    requiresLabelPerEdge: true, requiredMaximumConcurrentDraws: 2,
  }),
  "governed-runtime": Object.freeze({
    styleId: 6, name: "Claude Official", drawSchedule: STYLE_6_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[6], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 9,
    requiresLabelPerEdge: true, requiredMaximumConcurrentDraws: 2,
  }),
  "token-stream": Object.freeze({
    styleId: 7, name: "OpenAI Official", drawSchedule: STYLE_7_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[7], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 8,
    requiresLabelPerEdge: true, requiredMaximumConcurrentDraws: 3,
  }),
  "golden-circuit": Object.freeze({
    styleId: 8, name: "Dark Luxury", drawSchedule: STYLE_8_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[8], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 7,
    requiresLabelPerEdge: true, requiredMaximumConcurrentDraws: 2, stageAwareRouteKey: true,
  }),
  "review-trace": Object.freeze({
    styleId: 9, name: "C4 Review Canvas", drawSchedule: STYLE_9_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[9], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 5,
    requiresLabelPerEdge: true, requiredMaximumConcurrentDraws: 2,
  }),
  "cloud-flow": Object.freeze({
    styleId: 10, name: "Cloud Fabric", drawSchedule: STYLE_10_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[10], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 3,
    requiresLabelPerEdge: false, requiredMaximumConcurrentDraws: 2,
  }),
  "event-transit": Object.freeze({
    styleId: 11, name: "Event Transit", drawSchedule: STYLE_11_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[11], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 0,
    requiresLabelPerEdge: false, requiredMaximumConcurrentDraws: 2, stageAwareRouteKey: true,
  }),
  "ops-pulse": Object.freeze({
    styleId: 12, name: "Ops Pulse", drawSchedule: STYLE_12_DRAW_SCHEDULE,
    stream: SPECIALIZED_STREAM_CONTRACTS[12], signature: null, legacyStyleOneReport: false,
    streamMode: "specialized-live-signature", expectedRouteLabelCount: 0,
    requiresLabelPerEdge: false, requiredMaximumConcurrentDraws: 1, stageAwareRouteKey: true,
  }),
});
const PRESETS = new Set(Object.keys(SCENE_CONTRACTS));

function parseArguments(argv) {
  const values = {};
  for (let index = 0; index < argv.length; index += 1) {
    const argument = argv[index];
    if (argument === "--probe") {
      values.probe = true;
      continue;
    }
    if (!argument.startsWith("--") || index + 1 >= argv.length) {
      throw new Error(`Invalid argument: ${argument}`);
    }
    values[argument.slice(2)] = argv[index + 1];
    index += 1;
  }
  return values;
}

const { loadRenderer, chromeExecutable } = require("./renderer_runtime");

function probe() {
  const loaded = loadRenderer();
  const executable = chromeExecutable(loaded.api);
  if (!executable) {
    throw new Error("No compatible Chrome or Chromium executable was found");
  }
  return {
    ok: true,
    module: loaded.module,
    resolved_module: loaded.resolvedModule,
    module_version: loaded.moduleVersion,
    chrome: executable,
    deterministic_timeline: true,
    sandbox_default: "enabled",
    input: "semantic-svg",
    motion_model: "connector-draw-on-with-persistent-data-flow",
    presets: [...PRESETS],
  };
}

async function installMotionRuntime(page, preset, fps, frameCount) {
  const sceneContract = SCENE_CONTRACTS[preset];
  if (!sceneContract) {
    throw new Error(`Preset ${preset} is awaiting style review`);
  }
  return page.evaluate(
    ({
      selectedPreset,
      selectedFps,
      selectedFrameCount,
      selectedSceneContract,
      minimumFrameCount,
      emptyOpeningFrame,
      resetOpacitySamples,
    }) => {
      const SVG_NS = "http://www.w3.org/2000/svg";
      const root = document.querySelector("svg");
      if (!root) {
        throw new Error("SVG root is unavailable");
      }
      const drawSchedule = selectedSceneContract.drawSchedule;
      const persistentStreamContract = selectedSceneContract.stream;
      const signatureContract = selectedSceneContract.signature;
      const expectedStreamPhases = persistentStreamContract.expectedStreamPhases;
      if (Number(root.dataset.styleId) !== selectedSceneContract.styleId) {
        throw new Error(
          `Preset ${selectedPreset} belongs to Style ${selectedSceneContract.styleId}, input is Style ${root.dataset.styleId || "unknown"}`,
        );
      }
      if (selectedFrameCount < minimumFrameCount) {
        throw new Error(`${selectedSceneContract.name} requires at least ${minimumFrameCount} rendered frames`);
      }
      const renderedFrameMax = selectedFrameCount - 1;
      const resetRange = [selectedFrameCount - resetOpacitySamples.length, renderedFrameMax];
      const fullOpacityEnd = resetRange[0] - 1;

      const attributeSignature = (element) => Array.from(element.attributes)
        .map((attribute) => `${attribute.name}=${attribute.value}`)
        .sort()
        .join("\u001f");
      const directTextSignature = (element) => Array.from(element.childNodes)
        .filter((node) => node.nodeType === Node.TEXT_NODE)
        .map((node) => node.data)
        .join("\u001f");
      const staticDomSnapshot = [root, ...root.querySelectorAll("*")].map((element) => ({
        element,
        parent: element.parentNode,
        attributes: attributeSignature(element),
        directText: directTextSignature(element),
      }));
      const assertStaticDomUnchanged = () => {
        for (const entry of staticDomSnapshot) {
          if (
            !entry.element.isConnected ||
            entry.element.parentNode !== entry.parent ||
            attributeSignature(entry.element) !== entry.attributes ||
            directTextSignature(entry.element) !== entry.directText
          ) {
            const identity = entry.element.id
              || entry.element.dataset?.edgeId
              || entry.element.dataset?.nodeId
              || entry.element.tagName;
            throw new Error(`Motion mutated source SVG element: ${identity}`);
          }
        }
      };

      const edges = Array.from(root.querySelectorAll('[data-graph-role="edge"]'));
      const nodes = Array.from(root.querySelectorAll('[data-graph-role="node"]'));
      const routeLabels = Array.from(root.querySelectorAll('[data-graph-role="label"][data-owner]'));
      const routeOwnerDecorations = Array.from(
        root.querySelectorAll('[data-graph-role="decoration"][data-owner]'),
      );
      if (!edges.length || !nodes.length) {
        throw new Error("Semantic edges and nodes are required");
      }
      const routeKey = (role, order, stage) => selectedSceneContract.stageAwareRouteKey
        ? `${role}/${stage}/${order}`
        : `${role}/${order}`;
      const edgesByRouteKey = new Map();
      edges.forEach((edge) => {
        const role = edge.dataset.motionRole || "";
        const order = Number(edge.dataset.motionOrder);
        const stage = Number(edge.dataset.motionStage);
        if (!role || !Number.isInteger(order) || !Number.isInteger(stage)) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid motion metadata`);
        }
        const key = routeKey(role, order, stage);
        const matches = edgesByRouteKey.get(key) || [];
        matches.push(edge);
        edgesByRouteKey.set(key, matches);
      });
      const expectedRouteKeys = drawSchedule.map((entry) => routeKey(entry.role, entry.order, entry.stage));
      const missingRouteKeys = expectedRouteKeys.filter((key) => !edgesByRouteKey.has(key));
      const unexpectedRouteKeys = [...edgesByRouteKey.keys()].filter((key) => !expectedRouteKeys.includes(key));
      const duplicateRouteKeys = [...edgesByRouteKey.entries()]
        .filter(([, matches]) => matches.length !== 1)
        .map(([key]) => key);
      if (
        edges.length !== drawSchedule.length
        || missingRouteKeys.length
        || unexpectedRouteKeys.length
        || duplicateRouteKeys.length
      ) {
        throw new Error(
          `${selectedSceneContract.name} requires exact (motion role, motion order) coverage; `
          + `missing=${missingRouteKeys.join(",")}; unexpected=${unexpectedRouteKeys.join(",")}; duplicate=${duplicateRouteKeys.join(",")}`,
        );
      }
      const edgeForKey = (role, order, stage) => edgesByRouteKey.get(routeKey(role, order, stage))[0];
      const edgeForEntry = (entry) => edgeForKey(entry.role, entry.order, entry.stage);
      drawSchedule.forEach((entry) => {
        if (entry.stage !== undefined && Number(edgeForEntry(entry).dataset.motionStage) !== entry.stage) {
          throw new Error(`${selectedSceneContract.name} route ${routeKey(entry.role, entry.order, entry.stage)} has an invalid stage`);
        }
      });
      if (persistentStreamContract.expectedSourceColors) {
        const sourceColors = drawSchedule.map((entry) => edgeForEntry(entry).getAttribute("stroke"));
        if (sourceColors.some((color, index) => color !== persistentStreamContract.expectedSourceColors[index])) {
          throw new Error(
            `${selectedSceneContract.name} semantic route colors changed: expected `
            + `${persistentStreamContract.expectedSourceColors.join(",")}, got ${sourceColors.join(",")}`,
          );
        }
      }
      const labelCounts = new Map();
      routeLabels.forEach((label) => {
        const owner = label.dataset.owner || "";
        labelCounts.set(owner, (labelCounts.get(owner) || 0) + 1);
      });
      const edgeIds = new Set(edges.map((edge) => edge.dataset.edgeId || ""));
      const duplicateLabelOwners = [...labelCounts.entries()]
        .filter(([, count]) => count !== 1)
        .map(([owner]) => owner);
      const unknownLabelOwners = [...labelCounts.keys()].filter((owner) => !edgeIds.has(owner));
      const missingLabelOwners = edges
        .map((edge) => edge.dataset.edgeId || "")
        .filter((edgeId) => !labelCounts.has(edgeId));
      if (
        duplicateLabelOwners.length
        || unknownLabelOwners.length
        || (selectedSceneContract.requiresLabelPerEdge !== false && missingLabelOwners.length)
        || (
          selectedSceneContract.expectedRouteLabelCount !== undefined
          && routeLabels.length !== selectedSceneContract.expectedRouteLabelCount
        )
      ) {
        throw new Error(
          `${selectedSceneContract.name} route-owned label contract changed; `
          + `missing=${missingLabelOwners.join(",")}; unknown=${unknownLabelOwners.join(",")}; duplicate=${duplicateLabelOwners.join(",")}`,
        );
      }

      const concurrency = [];
      for (let frame = 0; frame <= renderedFrameMax; frame += 1) {
        concurrency.push(drawSchedule.filter((entry) => (
          selectedSceneContract.styleId >= 5
            ? frame > entry.start && frame < entry.end
            : frame >= entry.start && frame <= entry.end
        )).length);
      }
      const maximumConcurrentDraws = Math.max(...concurrency);
      if (maximumConcurrentDraws > selectedSceneContract.requiredMaximumConcurrentDraws) {
        throw new Error(
          `Draw-on schedule exceeds the ${selectedSceneContract.requiredMaximumConcurrentDraws}-connector concurrency limit`,
        );
      }
      if (
        selectedSceneContract.requiredMaximumConcurrentDraws !== undefined
        && maximumConcurrentDraws !== selectedSceneContract.requiredMaximumConcurrentDraws
      ) {
        throw new Error(`${selectedSceneContract.name} draw-on concurrency changed`);
      }

      const motionLayer = document.createElementNS(SVG_NS, "g");
      motionLayer.setAttribute("data-graph-role", "decoration");
      motionLayer.setAttribute("data-motion-layer", "connector-draw-on-with-persistent-data-flow");
      motionLayer.setAttribute("aria-hidden", "true");
      motionLayer.setAttribute("pointer-events", "none");
      const edgeHidingStyle = document.createElementNS(SVG_NS, "style");
      edgeHidingStyle.setAttribute("data-motion-source-edge-hider", "true");
      const sourceHidingSelectors = [
        '[data-graph-role="edge"]',
        '[data-graph-role="label"][data-owner]',
      ];
      if (selectedSceneContract.styleId === 11 || selectedSceneContract.styleId === 12) {
        sourceHidingSelectors.push(
          '[data-graph-role="decoration"][data-owner]:not([data-motion-primitive])',
        );
      }
      edgeHidingStyle.textContent = `${sourceHidingSelectors.join(",")}{visibility:hidden!important}`;
      motionLayer.append(edgeHidingStyle);
      const labelLayer = document.createElementNS(SVG_NS, "g");
      labelLayer.setAttribute("data-graph-role", "decoration");
      labelLayer.setAttribute("data-motion-layer", "route-label-arrivals");
      labelLayer.setAttribute("aria-hidden", "true");
      labelLayer.setAttribute("pointer-events", "none");
      const firstNode = nodes[0].parentNode === root ? nodes[0] : null;
      root.insertBefore(motionLayer, firstNode);

      const effects = [];
      const drawReports = [];
      const persistentStreamReports = [];
      const persistentPacketHeadReports = [];
      const registrationBeadReports = [];
      const notionMemoryCardReports = [];
      const specializedSignatureReports = [];
      const auxiliaryReports = [];
      const traceSpanRevealReports = [];
      const settledOwnerDecorationReports = [];
      const settledOwnerDecorationClones = [];
      const transientTraceSpanSources = [];
      let settledOwnerDirectionLayer = null;
      let waterfallScannerReport = null;
      let terminalPromptCursorReport = null;
      const clamped = (value, minimum = 0, maximum = 1) => Math.min(maximum, Math.max(minimum, value));
      const renderedFrameAtTime = (time) => clamped(
        time * selectedFps - 0.5,
        0,
        renderedFrameMax,
      );
      const inclusiveProgress = (frame, start, end) => clamped((frame - start + 1) / (end - start + 1));
      const resetOpacity = (frame) => {
        if (frame <= resetRange[0]) {
          return resetOpacitySamples[0];
        }
        const position = clamped(frame - resetRange[0], 0, resetOpacitySamples.length - 1);
        const lowerIndex = Math.floor(position);
        const upperIndex = Math.min(resetOpacitySamples.length - 1, Math.ceil(position));
        const fraction = position - lowerIndex;
        return resetOpacitySamples[lowerIndex]
          + (resetOpacitySamples[upperIndex] - resetOpacitySamples[lowerIndex]) * fraction;
      };
      const streamFadeIn = (frame) => {
        const position = clamped(
          frame - persistentStreamContract.start,
          0,
          persistentStreamContract.fadeInFactors.length - 1,
        );
        const lowerIndex = Math.floor(position);
        const upperIndex = Math.min(persistentStreamContract.fadeInFactors.length - 1, Math.ceil(position));
        const fraction = position - lowerIndex;
        return persistentStreamContract.fadeInFactors[lowerIndex]
          + (
            persistentStreamContract.fadeInFactors[upperIndex]
            - persistentStreamContract.fadeInFactors[lowerIndex]
          ) * fraction;
      };
      const removeCloneIdentity = (clone) => {
        for (const attribute of Array.from(clone.attributes)) {
          if (attribute.name === "id" || attribute.name.startsWith("data-")) {
            clone.removeAttribute(attribute.name);
          }
        }
      };
      const prepareDecoration = (edge, primitive, preserveMarkers) => {
        const clone = edge.cloneNode(false);
        removeCloneIdentity(clone);
        if (!preserveMarkers) {
          clone.removeAttribute("marker-start");
          clone.removeAttribute("marker-mid");
          clone.removeAttribute("marker-end");
        }
        clone.removeAttribute("filter");
        clone.setAttribute("data-graph-role", "decoration");
        clone.setAttribute("data-motion-primitive", primitive);
        clone.setAttribute("data-owner", edge.dataset.edgeId || "");
        clone.setAttribute("aria-hidden", "true");
        clone.setAttribute("pointer-events", "none");
        clone.setAttribute("display", "none");
        clone.setAttribute("opacity", "0");
        return clone;
      };

      function addDrawOnRoute(edge, entry) {
        if (typeof edge.getTotalLength !== "function") {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} does not support path drawing`);
        }
        const length = edge.getTotalLength();
        if (!Number.isFinite(length) || length <= 0) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid path length`);
        }
        const drawPath = prepareDecoration(edge, "connector-draw-on", false);
        drawPath.setAttribute("stroke-dasharray", `${length} ${length}`);
        drawPath.setAttribute("stroke-dashoffset", String(length));
        const settledPath = prepareDecoration(edge, "settled-connector", true);
        settledPath.removeAttribute("stroke-dasharray");
        settledPath.removeAttribute("stroke-dashoffset");
        motionLayer.append(drawPath, settledPath);

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          const opacity = resetOpacity(frame);
          if (frame < entry.start) {
            drawPath.setAttribute("display", "none");
            drawPath.setAttribute("opacity", "0");
            settledPath.setAttribute("display", "none");
            settledPath.setAttribute("opacity", "0");
            return;
          }
          if (frame < entry.end) {
            const startsIdleBatch = frame === entry.start && !drawSchedule.some((candidate) => (
              candidate !== entry && frame > candidate.start && frame < candidate.end
            ));
            const raw = selectedSceneContract.styleId >= 5
              ? clamped(
                (frame - entry.start + (startsIdleBatch ? 1 : 0))
                  / (entry.end - entry.start + (startsIdleBatch ? 1 : 0)),
              )
              : inclusiveProgress(frame, entry.start, entry.end);
            const progress = raw;
            drawPath.setAttribute("display", "inline");
            drawPath.setAttribute("opacity", String(opacity));
            drawPath.setAttribute("stroke-dashoffset", String(length * (1 - progress)));
            settledPath.setAttribute("display", "none");
            settledPath.setAttribute("opacity", "0");
            return;
          }
          drawPath.setAttribute("display", "none");
          drawPath.setAttribute("opacity", "0");
          settledPath.setAttribute("display", "inline");
          settledPath.setAttribute("opacity", String(opacity));
        });
        const drawReport = {
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          rendered_frames: [entry.start, entry.end],
          easing: "linear",
          marker_during_draw: false,
          marker_after_arrival: Boolean(edge.getAttribute("marker-end")),
        };
        if (!selectedSceneContract.legacyStyleOneReport) {
          drawReport.stage = Number(edge.dataset.motionStage);
          drawReport.order = Number(edge.dataset.motionOrder);
          drawReport.schedule_key = routeKey(entry.role, entry.order, entry.stage);
        }
        drawReports.push(drawReport);
      }

      function addPersistentDataFlow(edge, entry) {
        const sourceWidth = Number.parseFloat(edge.getAttribute("stroke-width") || "1.5");
        const rawBodyStrokeWidth = Math.min(
          persistentStreamContract.bodyWidthMaximum,
          Math.max(
            persistentStreamContract.bodyWidthMinimum,
            sourceWidth * persistentStreamContract.bodyWidthMultiplier,
          ),
        );
        const bodyStrokeWidth = persistentStreamContract.bodyWidthPrecision === undefined
          ? rawBodyStrokeWidth
          : Number(rawBodyStrokeWidth.toFixed(persistentStreamContract.bodyWidthPrecision));
        const motionStage = Number(edge.dataset.motionStage);
        const motionOrder = Number(edge.dataset.motionOrder);
        if (!Number.isFinite(motionStage) || !Number.isFinite(motionOrder)) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid stream phase metadata`);
        }
        const initialPhase = (
          (
            motionStage * persistentStreamContract.phaseStageMultiplier
            + motionOrder * 3
          ) % persistentStreamContract.dashPeriod
          + persistentStreamContract.dashPeriod
        ) % persistentStreamContract.dashPeriod;
        const streamColor = persistentStreamContract.bodyColor === "inherit-source-stroke"
          ? edge.getAttribute("stroke")
          : persistentStreamContract.bodyColor;
        const packetHeadColor = persistentStreamContract.headColor;
        const stream = prepareDecoration(edge, persistentStreamContract.bodyPrimitive, false);
        stream.setAttribute("fill", "none");
        stream.setAttribute("stroke", streamColor);
        stream.setAttribute("stroke-width", String(bodyStrokeWidth));
        stream.setAttribute("stroke-linecap", "round");
        stream.setAttribute("stroke-linejoin", "round");
        stream.setAttribute("stroke-dasharray", persistentStreamContract.bodyDashPattern.join(" "));

        const packetHead = prepareDecoration(edge, persistentStreamContract.headPrimitive, false);
        packetHead.setAttribute("fill", "none");
        packetHead.setAttribute("stroke", packetHeadColor);
        packetHead.setAttribute("stroke-width", String(persistentStreamContract.headStrokeWidth));
        packetHead.setAttribute("stroke-linecap", "round");
        packetHead.setAttribute("stroke-linejoin", "round");
        packetHead.setAttribute("stroke-dasharray", persistentStreamContract.headDashPattern.join(" "));
        motionLayer.append(stream, packetHead);

        const streamDecorations = [stream, packetHead];
        const markerFree = streamDecorations.every((decoration) => (
          !decoration.hasAttribute("marker-start")
          && !decoration.hasAttribute("marker-mid")
          && !decoration.hasAttribute("marker-end")
        ));
        const filterFree = streamDecorations.every((decoration) => !decoration.hasAttribute("filter"));
        if (!markerFree || !filterFree) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} stream pair must be marker-free and filter-free`);
        }

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start || frame > renderedFrameMax) {
            stream.setAttribute("display", "none");
            stream.setAttribute("opacity", "0");
            packetHead.setAttribute("display", "none");
            packetHead.setAttribute("opacity", "0");
            return;
          }
          const dashOffset = initialPhase
            + (frame - persistentStreamContract.start) * persistentStreamContract.dashOffsetPerFrame;
          const fade = streamFadeIn(frame) * resetOpacity(frame);
          stream.setAttribute("display", "inline");
          stream.setAttribute("opacity", String(persistentStreamContract.bodyOpacity * fade));
          stream.setAttribute("stroke-dashoffset", String(dashOffset));
          packetHead.setAttribute("display", "inline");
          packetHead.setAttribute("opacity", String(persistentStreamContract.headOpacity * fade));
          packetHead.setAttribute(
            "stroke-dashoffset",
            String(dashOffset + persistentStreamContract.headLeadOffset),
          );
        });
        const streamReport = {
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          primitive: persistentStreamContract.bodyPrimitive,
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          stroke_width: bodyStrokeWidth,
          color: streamColor,
          dash_pattern: persistentStreamContract.bodyDashPattern,
          dash_period: persistentStreamContract.dashPeriod,
          dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          initial_phase: initialPhase,
          phase_policy: persistentStreamContract.phasePolicy,
          motion_stage: motionStage,
          motion_order: motionOrder,
          direction: "source-to-target",
          opacity: persistentStreamContract.bodyOpacity,
          travel_easing: "linear",
          marker_free: markerFree,
          filter_free: filterFree,
        };
        const packetHeadReport = {
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          primitive: persistentStreamContract.headPrimitive,
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          stroke_width: persistentStreamContract.headStrokeWidth,
          color: packetHeadColor,
          dash_pattern: persistentStreamContract.headDashPattern,
          dash_period: persistentStreamContract.dashPeriod,
          dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          body_initial_phase: initialPhase,
          dash_offset_from_body: persistentStreamContract.headLeadOffset,
          initial_dash_offset: initialPhase + persistentStreamContract.headLeadOffset,
          direction: "source-to-target",
          opacity: persistentStreamContract.headOpacity,
          travel_easing: "linear",
          marker_free: markerFree,
          filter_free: filterFree,
        };
        if (!selectedSceneContract.legacyStyleOneReport) {
          streamReport.schedule_key = routeKey(entry.role, entry.order, entry.stage);
          streamReport.source_stroke = edge.getAttribute("stroke");
          packetHeadReport.schedule_key = routeKey(entry.role, entry.order, entry.stage);
          packetHeadReport.motion_stage = motionStage;
          packetHeadReport.motion_order = motionOrder;
        }
        persistentStreamReports.push(streamReport);
        persistentPacketHeadReports.push(packetHeadReport);
      }

      function addBlueprintDistributionWave(edge, entry) {
        if (typeof edge.getTotalLength !== "function" || typeof edge.getPointAtLength !== "function") {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} does not support registration-bead travel`);
        }
        const pathLength = edge.getTotalLength();
        if (!Number.isFinite(pathLength) || pathLength <= 0) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid registration-bead path length`);
        }
        const sourceWidth = Number.parseFloat(edge.getAttribute("stroke-width") || "1.5");
        if (sourceWidth !== persistentStreamContract.sourceStrokeWidth) {
          throw new Error(
            `Edge ${edge.dataset.edgeId || "unknown"} source stroke width changed: `
            + `expected ${persistentStreamContract.sourceStrokeWidth}, got ${sourceWidth}`,
          );
        }
        const rawBodyStrokeWidth = Math.min(
          persistentStreamContract.bodyWidthMaximum,
          Math.max(
            persistentStreamContract.bodyWidthMinimum,
            sourceWidth * persistentStreamContract.bodyWidthMultiplier,
          ),
        );
        const bodyStrokeWidth = Number(rawBodyStrokeWidth.toFixed(persistentStreamContract.bodyWidthPrecision));
        if (bodyStrokeWidth !== persistentStreamContract.resolvedStrokeWidth) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Blueprint wave width changed`);
        }
        const motionStage = Number(edge.dataset.motionStage);
        const motionOrder = Number(edge.dataset.motionOrder);
        if (!Number.isFinite(motionStage) || !Number.isFinite(motionOrder)) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid Blueprint phase metadata`);
        }
        const initialPhase = (
          (
            motionStage * persistentStreamContract.phaseStageMultiplier
            + motionOrder * persistentStreamContract.phaseOrderMultiplier
          ) % persistentStreamContract.dashPeriod
          + persistentStreamContract.dashPeriod
        ) % persistentStreamContract.dashPeriod;
        const sourceColor = edge.getAttribute("stroke");
        const stream = prepareDecoration(edge, persistentStreamContract.bodyPrimitive, false);
        stream.setAttribute("fill", "none");
        stream.setAttribute("stroke", sourceColor);
        stream.setAttribute("stroke-width", String(bodyStrokeWidth));
        stream.setAttribute("stroke-linecap", "round");
        stream.setAttribute("stroke-linejoin", "round");
        stream.setAttribute("stroke-dasharray", persistentStreamContract.bodyDashPattern.join(" "));

        const bead = document.createElementNS(SVG_NS, "circle");
        const initialPoint = edge.getPointAtLength(initialPhase % pathLength);
        bead.setAttribute("data-graph-role", "decoration");
        bead.setAttribute("data-motion-primitive", persistentStreamContract.beadPrimitive);
        bead.setAttribute("data-owner", edge.dataset.edgeId || "");
        bead.setAttribute("cx", String(initialPoint.x));
        bead.setAttribute("cy", String(initialPoint.y));
        bead.setAttribute("r", String(persistentStreamContract.beadRadius));
        bead.setAttribute("fill", persistentStreamContract.beadFill);
        bead.setAttribute("stroke", sourceColor);
        bead.setAttribute("stroke-width", String(persistentStreamContract.beadStrokeWidth));
        bead.setAttribute("opacity", "0");
        bead.setAttribute("aria-hidden", "true");
        bead.setAttribute("pointer-events", "none");
        motionLayer.append(stream, bead);

        const decorations = [stream, bead];
        const markerFree = decorations.every((decoration) => (
          !decoration.hasAttribute("marker-start")
          && !decoration.hasAttribute("marker-mid")
          && !decoration.hasAttribute("marker-end")
        ));
        const filterFree = decorations.every((decoration) => !decoration.hasAttribute("filter"));
        if (!markerFree || !filterFree) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Blueprint wave must be marker-free and filter-free`);
        }

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start || frame > renderedFrameMax) {
            stream.setAttribute("display", "none");
            stream.setAttribute("opacity", "0");
            bead.setAttribute("opacity", "0");
            return;
          }
          const liveFrame = frame - persistentStreamContract.start;
          const dashOffset = initialPhase + liveFrame * persistentStreamContract.dashOffsetPerFrame;
          const beadDistance = (
            (
              initialPhase + liveFrame * persistentStreamContract.beadAdvancePerFrame
            ) % pathLength
            + pathLength
          ) % pathLength;
          const point = edge.getPointAtLength(beadDistance);
          const fade = streamFadeIn(frame) * resetOpacity(frame);
          stream.setAttribute("display", "inline");
          stream.setAttribute("opacity", String(persistentStreamContract.bodyOpacity * fade));
          stream.setAttribute("stroke-dashoffset", String(dashOffset));
          bead.setAttribute("cx", String(point.x));
          bead.setAttribute("cy", String(point.y));
          bead.setAttribute("opacity", String(persistentStreamContract.beadOpacity * fade));
        });
        persistentStreamReports.push({
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          schedule_key: routeKey(entry.role, entry.order, entry.stage),
          primitive: persistentStreamContract.bodyPrimitive,
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          stroke_width: bodyStrokeWidth,
          color: sourceColor,
          source_stroke: sourceColor,
          dash_pattern: persistentStreamContract.bodyDashPattern,
          dash_period: persistentStreamContract.dashPeriod,
          dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          initial_phase: initialPhase,
          phase_policy: persistentStreamContract.phasePolicy,
          motion_stage: motionStage,
          motion_order: motionOrder,
          direction: "source-to-target",
          opacity: persistentStreamContract.bodyOpacity,
          travel_easing: "linear",
          marker_free: markerFree,
          filter_free: filterFree,
        });
        registrationBeadReports.push({
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          schedule_key: routeKey(entry.role, entry.order, entry.stage),
          primitive: persistentStreamContract.beadPrimitive,
          shape: "circle",
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          radius: persistentStreamContract.beadRadius,
          fill: persistentStreamContract.beadFill,
          stroke: sourceColor,
          stroke_width: persistentStreamContract.beadStrokeWidth,
          opacity: persistentStreamContract.beadOpacity,
          initial_path_distance: initialPhase,
          initial_point: { x: initialPoint.x, y: initialPoint.y },
          path_length: pathLength,
          path_advance_per_rendered_frame: persistentStreamContract.beadAdvancePerFrame,
          direction: "source-to-target",
          wrap: "target-end-to-source-start",
          animated_attributes: ["cx", "cy", "opacity"],
          motion_stage: motionStage,
          motion_order: motionOrder,
          marker_free: markerFree,
          filter_free: filterFree,
        });
      }

      function addNotionMemoryCardHandoff(edge, entry) {
        if (typeof edge.getTotalLength !== "function" || typeof edge.getPointAtLength !== "function") {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} does not support Notion memory-card travel`);
        }
        const pathLength = edge.getTotalLength();
        const endpointClearance = persistentStreamContract.endpointClearance;
        if (!Number.isFinite(pathLength) || pathLength <= endpointClearance * 2) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid Notion memory-card path length`);
        }
        const scheduleIndex = drawSchedule.findIndex((candidate) => (
          candidate.role === entry.role && candidate.order === entry.order
        ));
        if (scheduleIndex < 0) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} is absent from the Notion schedule`);
        }
        const sourceWidth = Number.parseFloat(edge.getAttribute("stroke-width") || "1.5");
        if (sourceWidth !== persistentStreamContract.sourceStrokeWidth) {
          throw new Error(
            `Edge ${edge.dataset.edgeId || "unknown"} source stroke width changed: `
            + `expected ${persistentStreamContract.sourceStrokeWidth}, got ${sourceWidth}`,
          );
        }
        const rawBodyStrokeWidth = Math.min(
          persistentStreamContract.bodyWidthMaximum,
          Math.max(
            persistentStreamContract.bodyWidthMinimum,
            sourceWidth * persistentStreamContract.bodyWidthMultiplier,
          ),
        );
        const bodyStrokeWidth = Number(rawBodyStrokeWidth.toFixed(persistentStreamContract.bodyWidthPrecision));
        if (bodyStrokeWidth !== persistentStreamContract.resolvedStrokeWidth) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Notion rail width changed`);
        }
        const motionStage = Number(edge.dataset.motionStage);
        const motionOrder = Number(edge.dataset.motionOrder);
        if (!Number.isFinite(motionStage) || !Number.isFinite(motionOrder)) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} has invalid Notion phase metadata`);
        }
        const initialPhase = (
          (
            motionStage * persistentStreamContract.phaseStageMultiplier
            + motionOrder * persistentStreamContract.phaseOrderMultiplier
          ) % persistentStreamContract.dashPeriod
          + persistentStreamContract.dashPeriod
        ) % persistentStreamContract.dashPeriod;
        const semanticColor = persistentStreamContract.semanticColors[scheduleIndex];
        const initialNormalizedProgress = persistentStreamContract.initialNormalizedProgress[scheduleIndex];
        const availableTravel = pathLength - endpointClearance * 2;
        const initialPathDistance = endpointClearance + initialNormalizedProgress * availableTravel;

        const normalizeRotation = (rotation) => {
          const normalized = ((rotation + 180) % 360 + 360) % 360 - 180;
          return Math.abs(normalized) < 1e-9 ? 0 : normalized;
        };
        const tangentRotationAtDistance = (distance) => {
          const delta = Math.min(0.25, availableTravel / 4);
          const before = edge.getPointAtLength(Math.max(0, distance - delta));
          const after = edge.getPointAtLength(Math.min(pathLength, distance + delta));
          return normalizeRotation(Math.atan2(after.y - before.y, after.x - before.x) * 180 / Math.PI);
        };
        const initialPoint = edge.getPointAtLength(initialPathDistance);
        const initialTangentRotation = tangentRotationAtDistance(initialPathDistance);
        const sentinel = persistentStreamContract.directionSentinels[scheduleIndex];
        if (
          !sentinel
          || sentinel.role !== entry.role
          || sentinel.order !== entry.order
          || Math.abs(initialTangentRotation - sentinel.tangentRotation) > 0.001
        ) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Notion tangent rotation changed`);
        }

        const stream = prepareDecoration(edge, persistentStreamContract.bodyPrimitive, false);
        stream.setAttribute("fill", "none");
        stream.setAttribute("stroke", semanticColor);
        stream.setAttribute("stroke-width", String(bodyStrokeWidth));
        stream.setAttribute("stroke-linecap", "round");
        stream.setAttribute("stroke-linejoin", "round");
        stream.setAttribute("stroke-dasharray", persistentStreamContract.bodyDashPattern.join(" "));

        const card = document.createElementNS(SVG_NS, "g");
        card.setAttribute("data-graph-role", "decoration");
        card.setAttribute("data-motion-primitive", persistentStreamContract.cardPrimitive);
        card.setAttribute("data-owner", edge.dataset.edgeId || "");
        card.setAttribute(
          "transform",
          `translate(${initialPoint.x} ${initialPoint.y}) rotate(${initialTangentRotation})`,
        );
        card.setAttribute("opacity", "0");
        card.setAttribute("aria-hidden", "true");
        card.setAttribute("pointer-events", "none");

        const outer = document.createElementNS(SVG_NS, "rect");
        outer.setAttribute("x", String(persistentStreamContract.outerRect.x));
        outer.setAttribute("y", String(persistentStreamContract.outerRect.y));
        outer.setAttribute("width", String(persistentStreamContract.outerRect.width));
        outer.setAttribute("height", String(persistentStreamContract.outerRect.height));
        outer.setAttribute("rx", String(persistentStreamContract.outerRect.rx));
        outer.setAttribute("fill", persistentStreamContract.cardFill);
        outer.setAttribute("stroke", semanticColor);
        outer.setAttribute("stroke-width", String(persistentStreamContract.cardStrokeWidth));

        const inkLines = persistentStreamContract.inkLines.map((geometry) => {
          const line = document.createElementNS(SVG_NS, "line");
          Object.entries(geometry).forEach(([name, value]) => line.setAttribute(name, String(value)));
          line.setAttribute("stroke", semanticColor);
          line.setAttribute("stroke-width", String(persistentStreamContract.inkStrokeWidth));
          line.setAttribute("stroke-linecap", persistentStreamContract.inkLinecap);
          line.setAttribute("shape-rendering", persistentStreamContract.inkShapeRendering);
          return line;
        });
        card.append(outer, ...inkLines);
        motionLayer.append(stream, card);

        const decorations = [stream, card, outer, ...inkLines];
        const markerFree = decorations.every((decoration) => (
          !decoration.hasAttribute("marker-start")
          && !decoration.hasAttribute("marker-mid")
          && !decoration.hasAttribute("marker-end")
        ));
        const filterFree = decorations.every((decoration) => !decoration.hasAttribute("filter"));
        const shadowFree = decorations.every((decoration) => (
          !decoration.hasAttribute("filter") && !decoration.hasAttribute("style")
        ));
        if (!markerFree || !filterFree || !shadowFree) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Notion handoff must be marker/filter/shadow-free`);
        }

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start || frame > renderedFrameMax) {
            stream.setAttribute("display", "none");
            stream.setAttribute("opacity", "0");
            card.setAttribute("opacity", "0");
            return;
          }
          const liveFrame = frame - persistentStreamContract.start;
          const dashOffset = initialPhase + liveFrame * persistentStreamContract.dashOffsetPerFrame;
          const cardDistance = endpointClearance + (
            (
              initialPathDistance - endpointClearance
              + liveFrame * persistentStreamContract.cardAdvancePerFrame
            ) % availableTravel
            + availableTravel
          ) % availableTravel;
          const point = edge.getPointAtLength(cardDistance);
          const tangentRotation = tangentRotationAtDistance(cardDistance);
          if (Math.abs(tangentRotation - sentinel.tangentRotation) > 0.001) {
            throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} Notion card left its declared tangent`);
          }
          const fade = streamFadeIn(frame) * resetOpacity(frame);
          stream.setAttribute("display", "inline");
          stream.setAttribute("opacity", String(persistentStreamContract.bodyOpacity * fade));
          stream.setAttribute("stroke-dashoffset", String(dashOffset));
          card.setAttribute("transform", `translate(${point.x} ${point.y}) rotate(${tangentRotation})`);
          card.setAttribute("opacity", String(persistentStreamContract.cardOpacity * fade));
        });

        persistentStreamReports.push({
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          schedule_key: routeKey(entry.role, entry.order, entry.stage),
          primitive: persistentStreamContract.bodyPrimitive,
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          stroke_width: bodyStrokeWidth,
          color: semanticColor,
          source_stroke: edge.getAttribute("stroke"),
          dash_pattern: persistentStreamContract.bodyDashPattern,
          dash_period: persistentStreamContract.dashPeriod,
          dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          initial_phase: initialPhase,
          phase_policy: persistentStreamContract.phasePolicy,
          motion_stage: motionStage,
          motion_order: motionOrder,
          direction: "source-to-target",
          opacity: persistentStreamContract.bodyOpacity,
          travel_easing: "linear",
          marker_free: markerFree,
          filter_free: filterFree,
        });
        notionMemoryCardReports.push({
          edge_id: edge.dataset.edgeId || "",
          role: entry.role,
          schedule_key: routeKey(entry.role, entry.order, entry.stage),
          primitive: persistentStreamContract.cardPrimitive,
          shape: "group",
          rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          outer_rect: {
            ...persistentStreamContract.outerRect,
            fill: persistentStreamContract.cardFill,
            stroke: semanticColor,
            stroke_width: persistentStreamContract.cardStrokeWidth,
          },
          ink_lines: persistentStreamContract.inkLines,
          ink_stroke: semanticColor,
          ink_stroke_width: persistentStreamContract.inkStrokeWidth,
          ink_linecap: persistentStreamContract.inkLinecap,
          ink_shape_rendering: persistentStreamContract.inkShapeRendering,
          opacity: persistentStreamContract.cardOpacity,
          semantic_color: semanticColor,
          path_length: pathLength,
          endpoint_clearance: endpointClearance,
          initial_normalized_progress: initialNormalizedProgress,
          initial_path_distance: initialPathDistance,
          initial_point: { x: initialPoint.x, y: initialPoint.y },
          tangent_rotation: initialTangentRotation,
          path_advance_per_rendered_frame: persistentStreamContract.cardAdvancePerFrame,
          direction: "source-to-target",
          wrap: "target-clearance-to-source-clearance",
          animated_attributes: ["transform", "opacity"],
          motion_stage: motionStage,
          motion_order: motionOrder,
          marker_free: markerFree,
          filter_free: filterFree,
          shadow_free: shadowFree,
        });
      }

      const parseGraphBounds = (element) => {
        const values = (element.dataset.graphBounds || "").split(",").map(Number);
        if (values.length !== 4 || values.some((value) => !Number.isFinite(value))) {
          throw new Error(`Element ${element.id || element.dataset.nodeId || element.dataset.containerId || "unknown"} has invalid graph bounds`);
        }
        return { x: values[0], y: values[1], width: values[2] - values[0], height: values[3] - values[1] };
      };
      const appendMotionAttributes = (element, primitive, owner) => {
        element.setAttribute("data-graph-role", "decoration");
        element.setAttribute("data-motion-primitive", primitive);
        element.setAttribute("data-owner", owner);
        element.setAttribute("aria-hidden", "true");
        element.setAttribute("pointer-events", "none");
      };
      const tangentRotationAt = (edge, distance, pathLength) => {
        const delta = Math.min(0.75, Math.max(0.2, pathLength / 200));
        const before = edge.getPointAtLength(Math.max(0, distance - delta));
        const after = edge.getPointAtLength(Math.min(pathLength, distance + delta));
        return Math.atan2(after.y - before.y, after.x - before.x) * 180 / Math.PI;
      };
      const ensureGemFilter = () => {
        const filterId = "fireworks-motion-gem-halo";
        if (!motionLayer.querySelector(`#${filterId}`)) {
          const defs = document.createElementNS(SVG_NS, "defs");
          const filter = document.createElementNS(SVG_NS, "filter");
          filter.setAttribute("id", filterId);
          filter.setAttribute("x", "-80%");
          filter.setAttribute("y", "-80%");
          filter.setAttribute("width", "260%");
          filter.setAttribute("height", "260%");
          const blur = document.createElementNS(SVG_NS, "feGaussianBlur");
          blur.setAttribute("stdDeviation", "1.4");
          filter.append(blur);
          defs.append(filter);
          motionLayer.prepend(defs);
        }
        return filterId;
      };
      const buildSpecializedSignature = (edge, entry, color) => {
        const owner = edge.dataset.edgeId || "";
        const group = document.createElementNS(SVG_NS, "g");
        let primitive = persistentStreamContract.signaturePrimitive;
        let geometry = {};
        let rearExtent = 0;
        let forwardExtent = 0;
        let filteredElementCount = 0;

        if (persistentStreamContract.signatureKind === "glass-task-capsule") {
          primitive = "glass-task-capsule";
          const plate = document.createElementNS(SVG_NS, "rect");
          plate.setAttribute("x", "-7"); plate.setAttribute("y", "-4.5");
          plate.setAttribute("width", "14"); plate.setAttribute("height", "9"); plate.setAttribute("rx", "3");
          plate.setAttribute("fill", color); plate.setAttribute("fill-opacity", "0.30");
          plate.setAttribute("stroke", "#ffffff"); plate.setAttribute("stroke-opacity", "0.78"); plate.setAttribute("stroke-width", "1");
          plate.setAttribute("data-motion-component", "translucent-plate");
          const highlight = document.createElementNS(SVG_NS, "line");
          highlight.setAttribute("x1", "-4"); highlight.setAttribute("y1", "-2.7");
          highlight.setAttribute("x2", "4"); highlight.setAttribute("y2", "-2.7");
          highlight.setAttribute("stroke", "#ffffff"); highlight.setAttribute("stroke-width", "1"); highlight.setAttribute("stroke-opacity", "0.85");
          highlight.setAttribute("data-motion-component", "white-highlight");
          const dots = [-2.5, 2.5].map((x) => {
            const dot = document.createElementNS(SVG_NS, "circle");
            dot.setAttribute("cx", String(x)); dot.setAttribute("cy", "1.2"); dot.setAttribute("r", "2");
            dot.setAttribute("fill", color); dot.setAttribute("stroke", "#ffffff"); dot.setAttribute("stroke-width", "0.6");
            dot.setAttribute("data-motion-component", "work-item-dot");
            return dot;
          });
          group.append(plate, highlight, ...dots);
          geometry = { shape: "rounded-translucent-plate", width: 14, height: 9, rx: 3, highlight_stroke_width: 1, work_item_dot_radius: 2, work_item_dot_count: 2 };
          rearExtent = 7; forwardExtent = 7;
        } else if (persistentStreamContract.signatureKind === "policy-seal") {
          primitive = "policy-seal";
          const hexagon = document.createElementNS(SVG_NS, "polygon");
          hexagon.setAttribute("points", "0,-6 5.2,-3 5.2,3 0,6 -5.2,3 -5.2,-3");
          hexagon.setAttribute("fill", "#fffaf0"); hexagon.setAttribute("fill-opacity", "0.30");
          hexagon.setAttribute("stroke", "#fffaf0"); hexagon.setAttribute("stroke-width", "1.2");
          hexagon.setAttribute("data-motion-component", "seal-hexagon");
          const dot = document.createElementNS(SVG_NS, "circle");
          dot.setAttribute("cx", "0"); dot.setAttribute("cy", "-1.2"); dot.setAttribute("r", "1.5"); dot.setAttribute("fill", color);
          dot.setAttribute("data-motion-component", "seal-center-dot");
          const bar = document.createElementNS(SVG_NS, "line");
          bar.setAttribute("x1", "-2"); bar.setAttribute("y1", "3"); bar.setAttribute("x2", "2"); bar.setAttribute("y2", "3");
          bar.setAttribute("stroke", color); bar.setAttribute("stroke-width", "1.4"); bar.setAttribute("stroke-linecap", "round");
          bar.setAttribute("data-motion-component", "approval-bar");
          group.append(hexagon, dot, bar);
          geometry = { shape: "warm-white-hexagonal-outline", width: 12, height: 12, center_dot_diameter: 3, approval_bar_width: 4, shadow: false, glow: false };
          rearExtent = 6; forwardExtent = 6;
        } else if (persistentStreamContract.signatureKind === "token-train") {
          primitive = "token-train";
          const opacities = [1, 0.72, 0.44];
          [-8, -2, 4].forEach((x, index) => {
            const cell = document.createElementNS(SVG_NS, "rect");
            cell.setAttribute("x", String(x)); cell.setAttribute("y", "-2"); cell.setAttribute("width", "4"); cell.setAttribute("height", "4"); cell.setAttribute("rx", "1");
            cell.setAttribute("fill", color); cell.setAttribute("fill-opacity", String(opacities[index]));
            cell.setAttribute("data-motion-component", `token-cell-${index + 1}`);
            group.append(cell);
          });
          geometry = { shape: "three-cell-token-train", group_width: 18, group_height: 8, cell_width: 4, cell_height: 4, cell_gap: 2, cell_opacities: opacities };
          rearExtent = 8; forwardExtent = 8;
        } else if (persistentStreamContract.signatureKind === "gem-tracer") {
          primitive = "gem-tracer";
          const tail = document.createElementNS(SVG_NS, "polygon");
          tail.setAttribute("points", "-4,0 -16,-2 -16,2"); tail.setAttribute("fill", color); tail.setAttribute("fill-opacity", "0.55");
          tail.setAttribute("data-motion-component", "tapered-tail");
          const halo = document.createElementNS(SVG_NS, "rect");
          halo.setAttribute("x", "-3.5"); halo.setAttribute("y", "-3.5"); halo.setAttribute("width", "7"); halo.setAttribute("height", "7");
          halo.setAttribute("transform", "rotate(45)"); halo.setAttribute("fill", color); halo.setAttribute("fill-opacity", "0.34");
          halo.setAttribute("filter", `url(#${ensureGemFilter()})`); halo.setAttribute("data-motion-component", "diamond-halo");
          const diamond = document.createElementNS(SVG_NS, "rect");
          diamond.setAttribute("x", "-3.5"); diamond.setAttribute("y", "-3.5"); diamond.setAttribute("width", "7"); diamond.setAttribute("height", "7");
          diamond.setAttribute("transform", "rotate(45)"); diamond.setAttribute("fill", color); diamond.setAttribute("stroke", "#fde68a"); diamond.setAttribute("stroke-width", "0.8");
          diamond.setAttribute("data-motion-component", "gem-diamond");
          const specular = document.createElementNS(SVG_NS, "circle");
          specular.setAttribute("cx", "1"); specular.setAttribute("cy", "-1"); specular.setAttribute("r", "1"); specular.setAttribute("fill", "#ffffff");
          specular.setAttribute("data-motion-component", "specular-point");
          group.append(tail, halo, diamond, specular);
          geometry = { shape: "diamond-with-tapered-tail", diamond_width: 7, diamond_height: 7, diamond_rotation: 45, specular_diameter: 2, tail_length: 12 };
          rearExtent = 16; forwardExtent = 5; filteredElementCount = 1;
        } else if (persistentStreamContract.signatureKind === "review-cursor") {
          primitive = "review-cursor";
          const circle = document.createElementNS(SVG_NS, "circle");
          circle.setAttribute("cx", "0"); circle.setAttribute("cy", "0"); circle.setAttribute("r", "5.5"); circle.setAttribute("fill", "none");
          circle.setAttribute("stroke", color); circle.setAttribute("stroke-width", "1.4"); circle.setAttribute("data-motion-component", "cursor-circle");
          const handle = document.createElementNS(SVG_NS, "line");
          handle.setAttribute("x1", "3.9"); handle.setAttribute("y1", "3.9"); handle.setAttribute("x2", "7.44"); handle.setAttribute("y2", "7.44");
          handle.setAttribute("stroke", color); handle.setAttribute("stroke-width", "1.4"); handle.setAttribute("stroke-linecap", "round"); handle.setAttribute("data-motion-component", "cursor-handle");
          const check = document.createElementNS(SVG_NS, "polyline");
          check.setAttribute("points", "-2,0 -0.5,1.5 2,-1.5"); check.setAttribute("fill", "none"); check.setAttribute("stroke", color); check.setAttribute("stroke-width", "1.2");
          check.setAttribute("stroke-linecap", "round"); check.setAttribute("stroke-linejoin", "round"); check.setAttribute("data-motion-component", "cursor-check");
          group.append(circle, handle, check);
          geometry = { shape: "review-mark", outline_circle_diameter: 11, diagonal_handle_length: 5, internal_check_extent: 3 };
          rearExtent = 6; forwardExtent = 8;
        } else if (persistentStreamContract.signatureKind === "cloud-flow") {
          if (entry.role === "cross-region") {
            primitive = "replication-capsule";
            const capsule = document.createElementNS(SVG_NS, "rect");
            capsule.setAttribute("x", "-7"); capsule.setAttribute("y", "-3.5"); capsule.setAttribute("width", "14"); capsule.setAttribute("height", "7"); capsule.setAttribute("rx", "3.5");
            capsule.setAttribute("fill", "#ffffff"); capsule.setAttribute("fill-opacity", "0.92"); capsule.setAttribute("stroke", color); capsule.setAttribute("stroke-width", "1.2");
            capsule.setAttribute("data-motion-component", "replication-outline");
            [-2.5, 2.5].forEach((x) => {
              const cell = document.createElementNS(SVG_NS, "circle");
              cell.setAttribute("cx", String(x)); cell.setAttribute("cy", "0"); cell.setAttribute("r", "1.5"); cell.setAttribute("fill", "#7c3aed");
              cell.setAttribute("data-motion-component", "replication-data-cell"); group.append(cell);
            });
            group.prepend(capsule);
            geometry = { shape: "replication-capsule", width: 14, height: 7, data_cell_count: 2, direction: "left-to-right" };
            rearExtent = 7; forwardExtent = 7;
          } else {
            primitive = "region-chevron-pair";
            [-2.5, 2.5].forEach((center) => {
              const chevron = document.createElementNS(SVG_NS, "path");
              chevron.setAttribute("d", `M ${center - 3},-2.5 L ${center},0 L ${center - 3},2.5`);
              chevron.setAttribute("fill", "none"); chevron.setAttribute("stroke", color); chevron.setAttribute("stroke-width", "1.6");
              chevron.setAttribute("stroke-linecap", "round"); chevron.setAttribute("stroke-linejoin", "round"); chevron.setAttribute("data-motion-component", "region-chevron");
              group.append(chevron);
            });
            geometry = { shape: "region-chevron-pair", chevron_width: 6, chevron_height: 5, separation: 5 };
            rearExtent = 6; forwardExtent = 3;
          }
        } else if (persistentStreamContract.signatureKind === "event-transit") {
          if (entry.role === "topic-rail") {
            primitive = "event-train";
            [-8, 0, 8].forEach((x) => {
              const car = document.createElementNS(SVG_NS, "circle");
              car.setAttribute("cx", String(x)); car.setAttribute("cy", "0"); car.setAttribute("r", "2.5"); car.setAttribute("fill", color);
              car.setAttribute("stroke", "#ffffff"); car.setAttribute("stroke-width", "0.6"); car.setAttribute("data-motion-component", "event-car"); group.append(car);
            });
            geometry = { shape: "three-car-event-train", car_diameter: 5, car_gap: 3, car_count: 3 };
            rearExtent = 10.5; forwardExtent = 10.5;
          } else if (entry.role === "dead-letter") {
            primitive = "exception-car";
            const exception = document.createElementNS(SVG_NS, "circle");
            exception.setAttribute("cx", "0"); exception.setAttribute("cy", "0"); exception.setAttribute("r", "4"); exception.setAttribute("fill", "#fff7f7");
            exception.setAttribute("stroke", "#c62828"); exception.setAttribute("stroke-width", "1.4"); exception.setAttribute("data-motion-component", "exception-outline");
            const mark = document.createElementNS(SVG_NS, "path");
            mark.setAttribute("d", "M 0,-2 L 0,1 M 0,2.5 L 0,2.6"); mark.setAttribute("stroke", "#c62828"); mark.setAttribute("stroke-width", "1.2"); mark.setAttribute("stroke-linecap", "round");
            mark.setAttribute("data-motion-component", "exception-mark"); group.append(exception, mark);
            geometry = { shape: "red-outlined-exception-car", diameter: 8 };
            rearExtent = 4; forwardExtent = 4;
          } else {
            primitive = "projection-car";
            [-6.5, 1.5].forEach((x) => {
              const cell = document.createElementNS(SVG_NS, "rect");
              cell.setAttribute("x", String(x)); cell.setAttribute("y", "-2.5"); cell.setAttribute("width", "5"); cell.setAttribute("height", "5"); cell.setAttribute("rx", "1.2");
              cell.setAttribute("fill", "#00897b"); cell.setAttribute("stroke", "#ffffff"); cell.setAttribute("stroke-width", "0.6"); cell.setAttribute("data-motion-component", "projection-cell"); group.append(cell);
            });
            geometry = { shape: "teal-two-cell-projection-car", cell_count: 2, cell_width: 5, cell_gap: 3 };
            rearExtent = 6.5; forwardExtent = 6.5;
          }
        } else if (persistentStreamContract.signatureKind === "ops-pulse") {
          if (entry.role === "critical-request") {
            primitive = "ecg-head";
            const ecg = document.createElementNS(SVG_NS, "polyline");
            ecg.setAttribute("points", "-10,0 -6,0 -4,-3.5 -1,3.5 2,-4.5 5,0 10,0"); ecg.setAttribute("fill", "none");
            ecg.setAttribute("stroke", "#fde68a"); ecg.setAttribute("stroke-width", "1.6"); ecg.setAttribute("stroke-linecap", "round"); ecg.setAttribute("stroke-linejoin", "round");
            ecg.setAttribute("data-motion-component", "ecg-waveform"); group.append(ecg);
            geometry = { shape: "compact-ecg-head", width: 20, stroke_width: 1.6 };
            rearExtent = 10; forwardExtent = 10;
          } else {
            primitive = "telemetry-export-packet";
            [-6, 0, 6].forEach((x, index) => {
              const dot = document.createElementNS(SVG_NS, "circle");
              dot.setAttribute("cx", String(x)); dot.setAttribute("cy", "0"); dot.setAttribute("r", "2"); dot.setAttribute("fill", "#22d3ee");
              dot.setAttribute("fill-opacity", String([0.48, 0.72, 1][index])); dot.setAttribute("data-motion-component", "telemetry-dot"); group.append(dot);
            });
            geometry = { shape: "cyan-three-dot-export-packet", dot_count: 3, dot_diameter: 4 };
            rearExtent = 8; forwardExtent = 8;
          }
        } else {
          throw new Error(`${selectedSceneContract.name} has no specialized signature builder`);
        }

        appendMotionAttributes(group, primitive, owner);
        group.setAttribute("opacity", "0");
        return { group, primitive, geometry, rearExtent, forwardExtent, filteredElementCount };
      };

      function addSpecializedLiveSignature(edge, entry) {
        if (typeof edge.getTotalLength !== "function" || typeof edge.getPointAtLength !== "function") {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} does not support specialized live travel`);
        }
        const pathLength = edge.getTotalLength();
        const sourceWidth = Number.parseFloat(edge.getAttribute("stroke-width") || "1.5");
        const bodyStrokeWidth = Number(Math.min(persistentStreamContract.bodyWidthMaximum, sourceWidth).toFixed(2));
        const motionStage = Number(edge.dataset.motionStage);
        const motionOrder = Number(edge.dataset.motionOrder);
        const initialPhase = (
          motionStage * persistentStreamContract.phaseStageMultiplier
          + motionOrder * persistentStreamContract.phaseOrderMultiplier
        ) % persistentStreamContract.dashPeriod;
        const sourceColor = edge.getAttribute("stroke") || "#64748b";
        const bodyPrimitive = selectedSceneContract.styleId === 12
          ? (entry.role === "critical-request" ? "incident-pulse-rail" : "telemetry-export-rail")
          : persistentStreamContract.bodyPrimitive;
        const stream = prepareDecoration(edge, bodyPrimitive, false);
        stream.setAttribute("fill", "none"); stream.setAttribute("stroke", sourceColor); stream.setAttribute("stroke-width", String(bodyStrokeWidth));
        stream.setAttribute("stroke-linecap", "round"); stream.setAttribute("stroke-linejoin", "round");
        stream.setAttribute("stroke-dasharray", persistentStreamContract.bodyDashPattern.join(" "));
        const signature = buildSpecializedSignature(edge, entry, sourceColor);
        const startDistance = persistentStreamContract.endpointClearance + signature.rearExtent;
        const endDistance = pathLength - persistentStreamContract.endpointClearance - signature.forwardExtent;
        const availableTravel = endDistance - startDistance;
        if (!Number.isFinite(pathLength) || availableTravel <= 0) {
          throw new Error(`Edge ${edge.dataset.edgeId || "unknown"} is too short for ${signature.primitive} clearance`);
        }
        const initialDistance = startDistance + (initialPhase % availableTravel);
        const initialPoint = edge.getPointAtLength(initialDistance);
        const initialRotation = tangentRotationAt(edge, initialDistance, pathLength);
        signature.group.setAttribute("transform", `translate(${initialPoint.x} ${initialPoint.y}) rotate(${initialRotation})`);
        motionLayer.append(stream, signature.group);

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start || frame > renderedFrameMax) {
            stream.setAttribute("display", "none"); stream.setAttribute("opacity", "0"); signature.group.setAttribute("opacity", "0");
            return;
          }
          const liveFrame = frame - persistentStreamContract.start;
          const dashOffset = initialPhase + liveFrame * persistentStreamContract.dashOffsetPerFrame;
          const distance = startDistance + (
            (initialDistance - startDistance + liveFrame * persistentStreamContract.advancePerFrame) % availableTravel
            + availableTravel
          ) % availableTravel;
          const point = edge.getPointAtLength(distance);
          const rotation = tangentRotationAt(edge, distance, pathLength);
          const fade = streamFadeIn(frame) * resetOpacity(frame);
          stream.setAttribute("display", "inline"); stream.setAttribute("opacity", String(persistentStreamContract.bodyOpacity * fade));
          stream.setAttribute("stroke-dashoffset", String(dashOffset));
          signature.group.setAttribute("transform", `translate(${point.x} ${point.y}) rotate(${rotation})`);
          signature.group.setAttribute("opacity", String(0.98 * fade));
        });

        const scheduleKey = routeKey(entry.role, entry.order, entry.stage);
        persistentStreamReports.push({
          edge_id: edge.dataset.edgeId || "", role: entry.role, schedule_key: scheduleKey,
          primitive: bodyPrimitive, rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          stroke_width: bodyStrokeWidth, maximum_live_width: persistentStreamContract.bodyWidthMaximum,
          source_stroke_width: sourceWidth, dynamic_not_thicker_than_source: bodyStrokeWidth <= sourceWidth,
          color: sourceColor, dash_pattern: persistentStreamContract.bodyDashPattern,
          dash_period: persistentStreamContract.dashPeriod, dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          initial_phase: initialPhase, phase_policy: persistentStreamContract.phasePolicy,
          motion_stage: motionStage, motion_order: motionOrder, direction: "source-to-target",
          opacity: persistentStreamContract.bodyOpacity, travel_easing: "linear", marker_free: true, filter_free: true,
        });
        specializedSignatureReports.push({
          edge_id: edge.dataset.edgeId || "", role: entry.role, schedule_key: scheduleKey,
          primitive: signature.primitive, signature_family: persistentStreamContract.signatureKind,
          geometry: signature.geometry, rendered_frames: [persistentStreamContract.start, renderedFrameMax],
          fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
          full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
          path_length: pathLength, endpoint_clearance: persistentStreamContract.endpointClearance,
          geometry_rear_extent: signature.rearExtent, geometry_forward_extent: signature.forwardExtent,
          center_travel_range: [startDistance, endDistance], initial_path_distance: initialDistance,
          initial_point: { x: initialPoint.x, y: initialPoint.y }, initial_tangent_rotation: initialRotation,
          path_advance_per_rendered_frame: persistentStreamContract.advancePerFrame,
          travel_pixels_per_rendered_frame_at_50_percent: persistentStreamContract.advancePerFrame / 2,
          direction: "source-to-target", wrap: "target-clearance-to-source-clearance",
          animated_attributes: ["transform", "opacity"], source_color: sourceColor,
          marker_free: true, filtered_element_count: signature.filteredElementCount,
          filter_boundary_valid: signature.filteredElementCount <= 1,
          appended_below_labels_and_nodes: true,
        });
      }

      const fixedPulseOpacity = (frame, period, minimum, maximum) => {
        const phase = ((frame - persistentStreamContract.start) % period + period) % period;
        const wave = 0.5 - 0.5 * Math.cos(2 * Math.PI * phase / period);
        return minimum + (maximum - minimum) * wave;
      };
      const addFixedNodeHalo = (config) => {
        const matches = nodes.filter((node) => node.dataset.nodeId === config.nodeId);
        if (matches.length !== 1) {
          throw new Error(`${selectedSceneContract.name} requires node ${config.nodeId} for its halo`);
        }
        const bounds = parseGraphBounds(matches[0]);
        const halo = document.createElementNS(SVG_NS, "rect");
        appendMotionAttributes(halo, config.primitive, config.nodeId);
        halo.setAttribute("x", String(bounds.x - 4)); halo.setAttribute("y", String(bounds.y - 4));
        halo.setAttribute("width", String(bounds.width + 8)); halo.setAttribute("height", String(bounds.height + 8)); halo.setAttribute("rx", "10");
        halo.setAttribute("fill", "none"); halo.setAttribute("stroke", selectedSceneContract.styleId === 12 ? "#f59e0b" : "#ffffff");
        halo.setAttribute("stroke-width", "2"); halo.setAttribute("opacity", "0");
        motionLayer.append(halo);
        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start) { halo.setAttribute("opacity", "0"); return; }
          const opacity = fixedPulseOpacity(frame, config.periodFrames, config.minimumOpacity, config.maximumOpacity)
            * streamFadeIn(frame) * resetOpacity(frame);
          halo.setAttribute("opacity", String(opacity));
        });
        auxiliaryReports.push({
          primitive: config.primitive, node_id: config.nodeId, count: 1,
          movement: "opacity-only", animated_attributes: ["opacity"], period_frames: config.periodFrames,
          opacity_range: [config.minimumOpacity, config.maximumOpacity], geometry: { x: bounds.x - 4, y: bounds.y - 4, width: bounds.width + 8, height: bounds.height + 8 },
          below_node: true, source_geometry_mutated: false,
        });
      };
      const addContainerPairPulse = (config) => {
        const reports = [];
        config.containerIds.forEach((containerId) => {
          const container = root.querySelector(`[data-graph-role="container"][data-container-id="${containerId}"]`);
          if (!container) throw new Error(`${selectedSceneContract.name} requires container ${containerId}`);
          const sourceBoundary = container.querySelector("rect");
          if (!sourceBoundary) throw new Error(`${selectedSceneContract.name} container ${containerId} has no boundary`);
          const pulse = sourceBoundary.cloneNode(false);
          removeCloneIdentity(pulse); appendMotionAttributes(pulse, config.primitive, containerId);
          pulse.setAttribute("fill", "none"); pulse.setAttribute("opacity", "0"); pulse.removeAttribute("filter");
          motionLayer.append(pulse);
          effects.push((time) => {
            const frame = renderedFrameAtTime(time);
            if (frame < persistentStreamContract.start) { pulse.setAttribute("opacity", "0"); return; }
            const opacity = fixedPulseOpacity(frame, config.periodFrames, config.minimumOpacity, config.maximumOpacity)
              * streamFadeIn(frame) * resetOpacity(frame);
            pulse.setAttribute("opacity", String(opacity));
          });
          reports.push({
            container_id: containerId, geometry_attributes: ["x", "y", "width", "height", "rx"].reduce((result, name) => ({ ...result, [name]: pulse.getAttribute(name) }), {}),
            stroke_width: pulse.getAttribute("stroke-width"), source_stroke_width: sourceBoundary.getAttribute("stroke-width"), geometry_and_stroke_unchanged: pulse.getAttribute("stroke-width") === sourceBoundary.getAttribute("stroke-width"),
          });
        });
        auxiliaryReports.push({ primitive: config.primitive, count: reports.length, movement: "opacity-only", animated_attributes: ["opacity"], phase_locked: true, period_frames: config.periodFrames, opacity_range: [config.minimumOpacity, config.maximumOpacity], containers: reports, source_geometry_mutated: false });
      };
      const addStationDwellRings = (config) => {
        const mainEntries = drawSchedule.filter((entry) => entry.role === "topic-rail");
        const reports = [];
        mainEntries.forEach((entry) => {
          const edge = edgeForEntry(entry);
          const target = nodes.find((node) => node.dataset.nodeId === edge.dataset.target);
          if (!target) throw new Error(`Transit target ${edge.dataset.target || "unknown"} is unavailable`);
          const bounds = parseGraphBounds(target);
          const ring = document.createElementNS(SVG_NS, "rect");
          appendMotionAttributes(ring, config.primitive, edge.dataset.target || "");
          ring.setAttribute("x", String(bounds.x - 4)); ring.setAttribute("y", String(bounds.y - 4));
          ring.setAttribute("width", String(bounds.width + 8)); ring.setAttribute("height", String(bounds.height + 8)); ring.setAttribute("rx", "10");
          ring.setAttribute("fill", "none"); ring.setAttribute("stroke", edge.getAttribute("stroke") || "#e4475b"); ring.setAttribute("stroke-width", "1.2"); ring.setAttribute("opacity", "0");
          motionLayer.append(ring);
          effects.push((time) => {
            const frame = renderedFrameAtTime(time);
            const elapsed = frame - entry.end;
            const opacity = elapsed >= 0 && elapsed < config.periodFrames
              ? Math.sin(Math.PI * (elapsed + 1) / (config.periodFrames + 1)) * 0.32 * resetOpacity(frame)
              : 0;
            ring.setAttribute("opacity", String(opacity));
          });
          reports.push({ edge_id: edge.dataset.edgeId || "", target_node_id: edge.dataset.target || "", arrival_frame: entry.end, period_frames: config.periodFrames, movement: "opacity-only", geometry_expansion_per_frame: 0, outside_node_border: true, fixed_geometry: { x: bounds.x - 4, y: bounds.y - 4, width: bounds.width + 8, height: bounds.height + 8 } });
        });
        auxiliaryReports.push({ primitive: config.primitive, count: reports.length, rings: reports, source_geometry_mutated: false });
      };
      const addOpsScannerAndTraceReveal = () => {
        const spansById = new Map(nodes.filter((node) => node.dataset.spanId).map((node) => [node.dataset.spanId, node]));
        const schedule = [
          { id: "span-root", start: 24, end: 27 }, { id: "span-api", start: 27, end: 30 },
          { id: "span-checkout", start: 30, end: 33 }, { id: "span-payment", start: 33, end: 36 },
        ];
        if (schedule.some((entry) => !spansById.has(entry.id))) throw new Error("Ops Pulse trace-span source set changed");
        edgeHidingStyle.textContent += '[data-graph-role="node"][data-span-id]:not([data-span-id=""]){visibility:hidden!important}';
        transientTraceSpanSources.push(...schedule.map((entry) => spansById.get(entry.id)));
        const spanBounds = schedule.map((entry) => parseGraphBounds(spansById.get(entry.id)));
        const plot = {
          x: Math.min(...spanBounds.map((bounds) => bounds.x)),
          y: Math.min(...spanBounds.map((bounds) => bounds.y)),
          x2: Math.max(...spanBounds.map((bounds) => bounds.x + bounds.width)),
          y2: Math.max(...spanBounds.map((bounds) => bounds.y + bounds.height)),
        };
        const defs = document.createElementNS(SVG_NS, "defs");
        const scannerClip = document.createElementNS(SVG_NS, "clipPath");
        scannerClip.setAttribute("id", "fireworks-ops-scanner-clip");
        const scannerClipRect = document.createElementNS(SVG_NS, "rect");
        scannerClipRect.setAttribute("x", String(plot.x)); scannerClipRect.setAttribute("y", String(plot.y));
        scannerClipRect.setAttribute("width", String(plot.x2 - plot.x)); scannerClipRect.setAttribute("height", String(plot.y2 - plot.y)); scannerClip.append(scannerClipRect); defs.append(scannerClip);
        motionLayer.append(defs);
        const scanner = document.createElementNS(SVG_NS, "g");
        appendMotionAttributes(scanner, "waterfall-scanner", "trace-waterfall"); scanner.setAttribute("clip-path", "url(#fireworks-ops-scanner-clip)"); scanner.setAttribute("opacity", "0");
        const tail = document.createElementNS(SVG_NS, "rect");
        tail.setAttribute("x", "-12"); tail.setAttribute("y", String(plot.y)); tail.setAttribute("width", "12"); tail.setAttribute("height", String(plot.y2 - plot.y)); tail.setAttribute("fill", "#22d3ee"); tail.setAttribute("fill-opacity", "0.14"); tail.setAttribute("data-motion-component", "scanner-tail");
        const line = document.createElementNS(SVG_NS, "line");
        line.setAttribute("x1", "0"); line.setAttribute("x2", "0"); line.setAttribute("y1", String(plot.y)); line.setAttribute("y2", String(plot.y2)); line.setAttribute("stroke", "#67e8f9"); line.setAttribute("stroke-width", "2"); line.setAttribute("data-motion-component", "scanner-line");
        scanner.append(tail, line); motionLayer.append(scanner);
        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < persistentStreamContract.start) { scanner.setAttribute("opacity", "0"); return; }
          const liveFrame = frame - persistentStreamContract.start;
          const progress = ((liveFrame % 34) + 34) % 34 / 33;
          const x = plot.x + progress * (plot.x2 - plot.x);
          scanner.setAttribute("transform", `translate(${x} 0)`);
          scanner.setAttribute("opacity", String(streamFadeIn(frame) * resetOpacity(frame)));
        });
        waterfallScannerReport = { primitive: "waterfall-scanner", width: 2, tail_width: 12, period_frames: 34, plot_bounds: [plot.x, plot.y, plot.x2, plot.y2], contained_by: "trace-waterfall", below_span_labels: true, movement: "horizontal-within-trace-plot", animated_attributes: ["transform", "opacity"] };

        schedule.forEach((entry, index) => {
          const source = spansById.get(entry.id);
          const bounds = spanBounds[index];
          const clip = document.createElementNS(SVG_NS, "clipPath");
          const clipId = `fireworks-trace-reveal-${index}`; clip.setAttribute("id", clipId);
          const clipRect = document.createElementNS(SVG_NS, "rect");
          clipRect.setAttribute("x", String(bounds.x)); clipRect.setAttribute("y", String(bounds.y)); clipRect.setAttribute("width", "0"); clipRect.setAttribute("height", String(bounds.height)); clip.append(clipRect); defs.append(clip);
          const clone = source.cloneNode(true);
          for (const element of [clone, ...clone.querySelectorAll("*")]) removeCloneIdentity(element);
          appendMotionAttributes(clone, "trace-span-reveal", entry.id); clone.setAttribute("clip-path", `url(#${clipId})`); clone.setAttribute("display", "none"); clone.setAttribute("opacity", "0"); motionLayer.append(clone);
          effects.push((time) => {
            const frame = renderedFrameAtTime(time);
            if (frame < entry.start) { clone.setAttribute("display", "none"); clone.setAttribute("opacity", "0"); clipRect.setAttribute("width", "0"); return; }
            const progress = frame >= entry.end ? 1 : clamped((frame - entry.start) / (entry.end - entry.start));
            clone.setAttribute("display", "inline"); clone.setAttribute("opacity", String(resetOpacity(frame))); clipRect.setAttribute("width", String(bounds.width * progress));
          });
          traceSpanRevealReports.push({ span_id: entry.id, parent_span: source.dataset.parentSpan || null, rendered_frames: [entry.start, entry.end], source_geometry: bounds, reveal: "left-to-right-clip", source_transiently_hidden: true, source_geometry_mutated: false, clone_geometry_immutable: true });
        });
      };
      const addSpecializedAuxiliaries = () => {
        if (selectedSceneContract.styleId === 12) {
          addOpsScannerAndTraceReveal();
        }
        const config = persistentStreamContract.auxiliary;
        if (!config) return;
        if (config.kind === "node-halo" || config.kind === "ops-pulse") addFixedNodeHalo(config);
        else if (config.kind === "container-pair-pulse") addContainerPairPulse(config);
        else if (config.kind === "station-dwell-rings") addStationDwellRings(config);
      };

      const addSettledOwnerDecorations = () => {
        if (![11, 12].includes(selectedSceneContract.styleId)) return;
        const casingLayer = document.createElementNS(SVG_NS, "g");
        casingLayer.setAttribute("data-graph-role", "decoration");
        casingLayer.setAttribute("data-motion-layer", "settled-route-casings");
        casingLayer.setAttribute("aria-hidden", "true");
        casingLayer.setAttribute("pointer-events", "none");
        settledOwnerDirectionLayer = document.createElementNS(SVG_NS, "g");
        settledOwnerDirectionLayer.setAttribute("data-graph-role", "decoration");
        settledOwnerDirectionLayer.setAttribute("data-motion-layer", "settled-route-directions");
        settledOwnerDirectionLayer.setAttribute("aria-hidden", "true");
        settledOwnerDirectionLayer.setAttribute("pointer-events", "none");
        const ownerRole = selectedSceneContract.styleId === 11 ? "topic-rail" : "critical-request";
        const expectedSourceCount = selectedSceneContract.styleId === 11 ? 8 : 9;
        const expectedPerOwner = selectedSceneContract.styleId === 11 ? 2 : 3;
        const mainEntries = drawSchedule.filter((entry) => entry.role === ownerRole);
        const expectedOwners = new Set(mainEntries.map((entry) => edgeForEntry(entry).dataset.edgeId || ""));
        const decorationsByOwner = new Map();
        routeOwnerDecorations.forEach((decoration) => {
          const owner = decoration.dataset.owner || "";
          const matches = decorationsByOwner.get(owner) || [];
          matches.push(decoration);
          decorationsByOwner.set(owner, matches);
        });
        if (
          routeOwnerDecorations.length !== expectedSourceCount
          || decorationsByOwner.size !== expectedOwners.size
          || [...decorationsByOwner.keys()].some((owner) => !expectedOwners.has(owner))
          || [...expectedOwners].some((owner) => (
            decorationsByOwner.get(owner) || []
          ).length !== expectedPerOwner)
        ) {
          throw new Error(`${selectedSceneContract.name} route-owned decoration source set changed`);
        }
        mainEntries.forEach((entry) => {
          const edge = edgeForEntry(entry);
          const owner = edge.dataset.edgeId || "";
          const sources = decorationsByOwner.get(owner) || [];
          const clones = sources.map((source) => {
            const clone = source.cloneNode(true);
            for (const element of [clone, ...clone.querySelectorAll("*")]) removeCloneIdentity(element);
            appendMotionAttributes(clone, "settled-owner-decoration", owner);
            clone.setAttribute("display", "none");
            clone.setAttribute("opacity", "0");
            const sourceOpacity = source.hasAttribute("opacity")
              ? Number(source.getAttribute("opacity"))
              : 1;
            if (!Number.isFinite(sourceOpacity) || sourceOpacity < 0 || sourceOpacity > 1) {
              throw new Error(`${selectedSceneContract.name} owner decoration ${source.id || owner} has invalid opacity`);
            }
            const cloneLayer = source.id.endsWith("-rail-casing")
              || source.id.endsWith("-critical-glow")
              ? casingLayer
              : settledOwnerDirectionLayer;
            cloneLayer.append(clone);
            settledOwnerDecorationClones.push(clone);
            return { clone, source, sourceOpacity };
          });
          effects.push((time) => {
            const frame = renderedFrameAtTime(time);
            clones.forEach(({ clone, sourceOpacity }) => {
              if (frame < entry.end) {
                clone.setAttribute("display", "none");
                clone.setAttribute("opacity", "0");
                return;
              }
              clone.setAttribute("display", "inline");
              clone.setAttribute("opacity", String(sourceOpacity * resetOpacity(frame)));
            });
          });
          settledOwnerDecorationReports.push({
            edge_id: owner,
            settle_frame: entry.end,
            source_ids: sources.map((source) => source.id),
            clone_count: clones.length,
            hidden_before_settle: true,
            source_geometry_mutated: false,
          });
        });
        motionLayer.append(casingLayer);
      };

      function addRouteLabel(label, edge, entry) {
        const labelClone = label.cloneNode(true);
        for (const element of [labelClone, ...labelClone.querySelectorAll("*")]) {
          for (const attribute of Array.from(element.attributes)) {
            if (attribute.name === "id" || attribute.name.startsWith("data-")) {
              element.removeAttribute(attribute.name);
            }
          }
        }
        labelClone.setAttribute("data-graph-role", "decoration");
        labelClone.setAttribute("data-motion-primitive", "route-label-arrival");
        labelClone.setAttribute("data-owner", edge.dataset.edgeId || "");
        labelClone.setAttribute("aria-hidden", "true");
        labelClone.setAttribute("pointer-events", "none");
        labelClone.setAttribute("display", "none");
        labelClone.setAttribute("opacity", "0");
        labelLayer.append(labelClone);
        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          if (frame < entry.end) {
            labelClone.setAttribute("display", "none");
            labelClone.setAttribute("opacity", "0");
            return;
          }
          labelClone.setAttribute("display", "inline");
          labelClone.setAttribute("opacity", String(resetOpacity(frame)));
        });
      }

      function addTerminalPromptCursor(contract) {
        const terminalNodes = nodes.filter((node) => node.dataset.nodeId === contract.nodeId);
        if (terminalNodes.length !== 1) {
          throw new Error(`${selectedSceneContract.name} requires exactly one terminal node`);
        }
        const sourceTexts = Array.from(terminalNodes[0].querySelectorAll("text"))
          .filter((text) => (text.textContent || "").trim() === contract.sourceText);
        if (sourceTexts.length !== 1) {
          throw new Error(`${selectedSceneContract.name} requires exactly one terminal prompt underscore`);
        }
        const sourceText = sourceTexts[0];
        const bounds = sourceText.getBBox();
        if (
          !Number.isFinite(bounds.x)
          || !Number.isFinite(bounds.y)
          || !Number.isFinite(bounds.width)
          || !Number.isFinite(bounds.height)
          || bounds.width <= 0
          || bounds.height < contract.height
        ) {
          throw new Error(`${selectedSceneContract.name} terminal prompt underscore has invalid bounds`);
        }

        const signatureLayer = document.createElementNS(SVG_NS, "g");
        signatureLayer.setAttribute("data-graph-role", "decoration");
        signatureLayer.setAttribute("data-motion-layer", "terminal-signature");
        signatureLayer.setAttribute("aria-hidden", "true");
        signatureLayer.setAttribute("pointer-events", "none");
        const cursor = document.createElementNS(SVG_NS, "rect");
        cursor.setAttribute("data-graph-role", "decoration");
        cursor.setAttribute("data-motion-primitive", contract.primitive);
        cursor.setAttribute("data-owner", contract.nodeId);
        cursor.setAttribute("x", String(bounds.x));
        cursor.setAttribute("y", String(bounds.y + bounds.height - contract.height));
        cursor.setAttribute("width", String(bounds.width));
        cursor.setAttribute("height", String(contract.height));
        cursor.setAttribute("fill", contract.fill);
        cursor.setAttribute("opacity", "0");
        cursor.setAttribute("aria-hidden", "true");
        cursor.setAttribute("pointer-events", "none");
        signatureLayer.append(cursor);
        root.append(signatureLayer);

        const markerFree = !cursor.hasAttribute("marker-start")
          && !cursor.hasAttribute("marker-mid")
          && !cursor.hasAttribute("marker-end");
        const filterFree = !cursor.hasAttribute("filter");
        if (!markerFree || !filterFree) {
          throw new Error("Terminal prompt cursor must be marker-free and filter-free");
        }

        effects.push((time) => {
          const frame = renderedFrameAtTime(time);
          let opacity = 0;
          if (frame >= resetRange[0]) {
            opacity = contract.brightOpacity * resetOpacity(frame);
          } else if (frame >= contract.start && frame <= fullOpacityEnd) {
            const cadenceFrame = Math.floor(frame - contract.start + 1e-9) % contract.periodFrames;
            opacity = cadenceFrame < contract.brightFrames ? contract.brightOpacity : 0;
          }
          cursor.setAttribute("opacity", String(opacity));
        });
        terminalPromptCursorReport = {
          primitive: contract.primitive,
          count: 1,
          node_id: contract.nodeId,
          source_text: contract.sourceText,
          source_text_hidden: false,
          source_text_mutated: false,
          geometry: "2.2px-high rectangle derived from underscore getBBox",
          source_text_bounds: {
            x: bounds.x,
            y: bounds.y,
            width: bounds.width,
            height: bounds.height,
          },
          rectangle: {
            x: bounds.x,
            y: bounds.y + bounds.height - contract.height,
            width: bounds.width,
            height: contract.height,
          },
          fill: contract.fill,
          movement: "opacity-only",
          animated_attributes: ["opacity"],
          settled_after: {
            role: "tool-call",
            order: 0,
            frame: contract.start,
          },
          cadence_frames: [contract.start, fullOpacityEnd],
          period_frames: contract.periodFrames,
          bright_frames_per_period: contract.brightFrames,
          absent_frames_per_period: contract.absentFrames,
          bright_opacity: contract.brightOpacity,
          reset_range: resetRange,
          reset_behavior: "bright opacity multiplied by shared reset opacity",
          marker_free: markerFree,
          filter_free: filterFree,
        };
      }

      addSettledOwnerDecorations();
      drawSchedule.forEach((entry) => {
        addDrawOnRoute(edgeForEntry(entry), entry);
      });
      if (settledOwnerDirectionLayer) motionLayer.append(settledOwnerDirectionLayer);
      drawSchedule.forEach((entry) => {
        if (selectedSceneContract.streamMode === "blueprint-registration-bead") {
          addBlueprintDistributionWave(edgeForEntry(entry), entry);
        } else if (selectedSceneContract.streamMode === "notion-memory-card-handoff") {
          addNotionMemoryCardHandoff(edgeForEntry(entry), entry);
        } else if (selectedSceneContract.streamMode === "specialized-live-signature") {
          addSpecializedLiveSignature(edgeForEntry(entry), entry);
        } else {
          addPersistentDataFlow(edgeForEntry(entry), entry);
        }
      });
      if (selectedSceneContract.streamMode === "specialized-live-signature") {
        addSpecializedAuxiliaries();
      }
      const greatestCommonDivisor = (left, right) => {
        let a = Math.abs(left);
        let b = Math.abs(right);
        while (b) {
          [a, b] = [b, a % b];
        }
        return a;
      };
      const phaseStep = Math.abs(persistentStreamContract.dashOffsetPerFrame);
      if (greatestCommonDivisor(persistentStreamContract.dashPeriod, phaseStep) !== 1) {
        throw new Error("Persistent stream dash period and travel step must be coprime");
      }
      const actualStreamPhases = persistentStreamReports.map((report) => report.initial_phase);
      if (
        actualStreamPhases.length !== expectedStreamPhases.length
        || actualStreamPhases.some((phase, index) => phase !== expectedStreamPhases[index])
      ) {
        throw new Error(
          `${selectedSceneContract.name} stream phases changed: expected ${expectedStreamPhases.join(",")}, got ${actualStreamPhases.join(",")}`,
        );
      }
      if (selectedSceneContract.streamMode === "blueprint-registration-bead") {
        const reportsForRole = (role) => persistentStreamReports.filter((report) => report.role === role);
        const fanout = reportsForRole("fanout");
        const dataWrite = reportsForRole("data-write");
        if (
          fanout.length !== 3
          || fanout.some((report) => report.initial_phase !== 21)
          || dataWrite.length !== 3
          || dataWrite.some((report) => report.initial_phase !== 28)
        ) {
          throw new Error("Blueprint fanout/data-write stage locks changed");
        }
        const dataWriteBeads = registrationBeadReports.filter((report) => report.role === "data-write");
        const pathLengths = dataWriteBeads.map((report) => report.path_length);
        const initialY = dataWriteBeads.map((report) => report.initial_point.y);
        if (
          dataWriteBeads.length !== 3
          || !pathLengths.every((length) => Math.abs(length - pathLengths[0]) < 0.001)
          || !initialY.every((value) => Math.abs(value - initialY[0]) < 0.001)
        ) {
          throw new Error("Blueprint data-write registration beads lost path-length/Y synchrony");
        }
      } else if (selectedSceneContract.streamMode === "notion-memory-card-handoff") {
        const progressVector = notionMemoryCardReports.map((report) => report.initial_normalized_progress);
        const rotationVector = notionMemoryCardReports.map((report) => report.tangent_rotation);
        const colorVector = notionMemoryCardReports.map((report) => report.semantic_color);
        if (
          progressVector.length !== persistentStreamContract.initialNormalizedProgress.length
          || progressVector.some((progress, index) => (
            progress !== persistentStreamContract.initialNormalizedProgress[index]
          ))
          || rotationVector.some((rotation, index) => (
            rotation !== persistentStreamContract.directionSentinels[index].tangentRotation
          ))
          || colorVector.some((color, index) => color !== persistentStreamContract.semanticColors[index])
        ) {
          throw new Error("Notion memory-card progress, tangent, or semantic-color vector changed");
        }
      }
      drawSchedule.forEach((entry) => {
        const edge = edgeForEntry(entry);
        const label = routeLabels.find((candidate) => candidate.dataset.owner === edge.dataset.edgeId);
        if (label) {
          addRouteLabel(label, edge, entry);
        }
      });
      motionLayer.append(labelLayer);
      if (signatureContract) {
        addTerminalPromptCursor(signatureContract);
      }

      const sampledDirections = (edge) => {
        const length = edge.getTotalLength();
        const sampleCount = Math.max(64, Math.ceil(length / 3));
        const directions = [];
        let previous = edge.getPointAtLength(0);
        for (let index = 1; index <= sampleCount; index += 1) {
          const point = edge.getPointAtLength(length * index / sampleCount);
          const deltaX = point.x - previous.x;
          const deltaY = point.y - previous.y;
          previous = point;
          if (Math.abs(deltaX) < 0.001 && Math.abs(deltaY) < 0.001) {
            continue;
          }
          const direction = Math.abs(deltaX) >= Math.abs(deltaY)
            ? (deltaX > 0 ? "right" : "left")
            : (deltaY > 0 ? "down" : "up");
          if (directions[directions.length - 1] !== direction) {
            directions.push(direction);
          }
        }
        return directions;
      };
      const containsOrderedDirections = (actual, expected) => {
        let expectedIndex = 0;
        actual.forEach((direction) => {
          if (direction === expected[expectedIndex]) {
            expectedIndex += 1;
          }
        });
        return expectedIndex === expected.length;
      };
      const directionSentinels = persistentStreamContract.directionSentinels.map((sentinel) => {
        const actual = sampledDirections(edgeForKey(sentinel.role, sentinel.order, sentinel.stage));
        const passed = selectedSceneContract.streamMode === "notion-memory-card-handoff"
          ? actual.length === sentinel.expected.length
            && actual.every((direction, index) => direction === sentinel.expected[index])
          : containsOrderedDirections(actual, sentinel.expected);
        const beadTravelPassed = selectedSceneContract.streamMode !== "blueprint-registration-bead"
          || persistentStreamContract.beadAdvancePerFrame > 0;
        const cardTravelPassed = selectedSceneContract.streamMode !== "notion-memory-card-handoff"
          || (
            persistentStreamContract.cardAdvancePerFrame > 0
            && notionMemoryCardReports.some((report) => (
              report.role === sentinel.role
              && report.motion_order === sentinel.order
              && report.tangent_rotation === sentinel.tangentRotation
            ))
          );
        if (
          !passed
          || persistentStreamContract.dashOffsetPerFrame >= 0
          || !beadTravelPassed
          || !cardTravelPassed
        ) {
          throw new Error(
            `Stream direction sentinel failed for ${routeKey(sentinel.role, sentinel.order, sentinel.stage)}: `
            + `expected ${sentinel.expected.join(" -> ")}, got ${actual.join(" -> ")}`,
          );
        }
        const report = {
          role: sentinel.role,
          expected: sentinel.expected,
          actual,
          dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
          ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
            bead_advance_per_rendered_frame: persistentStreamContract.beadAdvancePerFrame,
          } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
            card_advance_per_rendered_frame: persistentStreamContract.cardAdvancePerFrame,
            tangent_rotation: sentinel.tangentRotation,
          } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
            signature_advance_per_rendered_frame: persistentStreamContract.advancePerFrame,
          } : {}),
          passed,
        };
        if (!selectedSceneContract.legacyStyleOneReport) {
          report.order = sentinel.order;
          if (sentinel.stage !== undefined) report.stage = sentinel.stage;
          report.schedule_key = routeKey(sentinel.role, sentinel.order, sentinel.stage);
        }
        return report;
      });
      if (!effects.length) {
        throw new Error(`${selectedSceneContract.name} did not create connector draw-on effects`);
      }

      window.__fireworksSetMotionTime = (time) => {
        effects.forEach((effect) => effect(time));
        assertStaticDomUnchanged();
      };
      window.__fireworksSetMotionFrame = (frameIndex) => {
        if (!Number.isInteger(frameIndex) || frameIndex < 0 || frameIndex > renderedFrameMax) {
          throw new Error(`Motion frame index ${frameIndex} is outside 0-${renderedFrameMax}`);
        }
        window.__fireworksSetMotionTime((frameIndex + 0.5) / selectedFps);
      };
      window.__fireworksSetMotionFrame(0);
      const isRenderedVisible = (element) => {
        const style = window.getComputedStyle(element);
        return style.display !== "none"
          && style.visibility !== "hidden"
          && Number(style.opacity || "1") > 0;
      };
      const ownerDecorationSourceOpeningVisibleCount = [11, 12].includes(selectedSceneContract.styleId)
        ? routeOwnerDecorations.filter(isRenderedVisible).length
        : 0;
      const ownerDecorationCloneOpeningVisibleCount = [11, 12].includes(selectedSceneContract.styleId)
        ? settledOwnerDecorationClones.filter(isRenderedVisible).length
        : 0;
      const traceSpanSourceOpeningVisibleCount = selectedSceneContract.styleId === 12
        ? transientTraceSpanSources.filter(isRenderedVisible).length
        : 0;
      const nonTraceSpanNodeOpeningHiddenCount = selectedSceneContract.styleId === 12
        ? nodes.filter((node) => !node.dataset.spanId).filter((node) => !isRenderedVisible(node)).length
        : 0;
      if (ownerDecorationSourceOpeningVisibleCount || ownerDecorationCloneOpeningVisibleCount) {
        throw new Error(`${selectedSceneContract.name} route-owner decoration leaked into the empty opening frame`);
      }
      if (traceSpanSourceOpeningVisibleCount) {
        throw new Error("Ops Pulse source trace spans leaked into the empty opening frame");
      }
      if (nonTraceSpanNodeOpeningHiddenCount) {
        throw new Error("Ops Pulse non-trace nodes were hidden in the empty opening frame");
      }

      return {
        effects: effects.length,
        edges: edges.length,
        nodes: nodes.length,
        fps: selectedFps,
        frame_count: selectedFrameCount,
        scene_report: {
          grammar_version: "3.4",
          preset: selectedPreset,
          primitive: "connector-draw-on-with-persistent-data-flow",
          empty_opening_frame: emptyOpeningFrame,
          connectors_visible_at_opening: false,
          nodes_visible_every_frame: true,
          topology_draw_on: true,
          settled_topology_dynamic: true,
          static_dom_guard: true,
          source_edges_hidden_by_transient_css: true,
          source_edges: edges.length,
          source_route_labels: routeLabels.length,
          draw_clones: drawReports.length,
          settled_marker_clones: drawReports.length,
          stream_count: persistentStreamReports.length,
          packet_head_count: persistentPacketHeadReports.length,
          ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
            registration_bead_count: registrationBeadReports.length,
          } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
            notion_memory_card_count: notionMemoryCardReports.length,
          } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
            specialized_signature_count: specializedSignatureReports.length,
          } : {}),
          route_label_clones: routeLabels.length,
          node_motion: 0,
          text_motion: 0,
          text_geometry_motion: 0,
          route_label_opacity_states: routeLabels.length,
          halo_count: selectedSceneContract.streamMode === "specialized-live-signature"
            ? auxiliaryReports.filter((report) => String(report.primitive || "").includes("halo")).reduce((total, report) => total + Number(report.count || 0), 0)
            : 0,
          ripple_count: 0,
          maximum_concurrent_draws: maximumConcurrentDraws,
          draw_schedule: drawReports,
          persistent_streams: persistentStreamReports,
          persistent_packet_heads: persistentPacketHeadReports,
          ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
            blueprint_registration_beads: registrationBeadReports,
          } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
            notion_memory_cards: notionMemoryCardReports,
          } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
            specialized_signatures: specializedSignatureReports,
            auxiliary_primitives: auxiliaryReports,
            trace_span_reveals: traceSpanRevealReports,
            waterfall_scanner: waterfallScannerReport,
          } : {}),
          direction_sentinels: directionSentinels,
          ...(selectedSceneContract.styleId === 2 ? {
            schedule_key: "(data-motion-role, data-motion-order)",
            cursor_count: terminalPromptCursorReport ? 1 : 0,
            terminal_prompt_cursor: terminalPromptCursorReport,
            extra_scene_primitives: terminalPromptCursorReport ? ["terminal-prompt-cursor"] : [],
            node_glow_pulse_count: 0,
            terminal_text_typing_count: 0,
            scan_line_count: 0,
            camera_motion_count: 0,
            animated_background_count: 0,
          } : selectedSceneContract.styleId === 3 ? {
            schedule_key: "(data-motion-role, data-motion-order)",
            extra_scene_primitives: [],
            node_glow_pulse_count: 0,
            terminal_text_typing_count: 0,
            terminal_cursor_count: 0,
            scan_line_count: 0,
            camera_motion_count: 0,
            animated_background_count: 0,
            blur_count: 0,
            shadow_count: 0,
            stage_locks: {
              fanout: { orders: [0, 1, 2], phase: 21 },
              data_write: { orders: [0, 1, 2], phase: 28, equal_length_paths: true },
            },
          } : selectedSceneContract.styleId === 4 ? {
            schedule_key: "(data-motion-role, data-motion-order)",
            extra_scene_primitives: ["notion-memory-card"],
            node_glow_pulse_count: 0,
            terminal_text_typing_count: 0,
            terminal_cursor_count: 0,
            circular_bead_count: 0,
            scan_line_count: 0,
            camera_motion_count: 0,
            animated_background_count: 0,
            blur_count: 0,
            shadow_count: 0,
            semantic_color_vector: persistentStreamContract.semanticColors,
            initial_progress_vector: persistentStreamContract.initialNormalizedProgress,
          } : selectedSceneContract.styleId >= 5 ? {
            schedule_key: selectedSceneContract.stageAwareRouteKey
              ? "(data-motion-role, data-motion-stage, data-motion-order)"
              : "(data-motion-role, data-motion-order)",
            scene_identity: selectedSceneContract.name,
            signature_kind: persistentStreamContract.signatureKind,
            extra_scene_primitives: [...new Set([
              ...specializedSignatureReports.map((report) => report.primitive),
              ...auxiliaryReports.map((report) => report.primitive),
              ...traceSpanRevealReports.map(() => "trace-span-reveal"),
              ...(waterfallScannerReport ? ["waterfall-scanner"] : []),
            ])],
            maximum_live_rail_width: Math.max(...persistentStreamReports.map((report) => report.stroke_width)),
            live_rail_width_ceiling: persistentStreamContract.bodyWidthMaximum,
            live_rail_width_ceiling_passed: persistentStreamReports.every((report) => report.stroke_width <= persistentStreamContract.bodyWidthMaximum),
            dynamic_not_thicker_than_source: persistentStreamReports.every((report) => report.dynamic_not_thicker_than_source),
            signature_travel_at_100_percent: persistentStreamContract.advancePerFrame,
            signature_travel_at_50_percent: persistentStreamContract.advancePerFrame / 2,
            source_geometry_mutation_count: 0,
            source_text_mutation_count: 0,
            source_marker_mutation_count: 0,
            node_motion_count: 0,
            text_motion_count: 0,
            camera_motion_count: 0,
            animated_background_count: 0,
            ...(selectedSceneContract.styleId === 8 ? {
              gem_filter_boundary: {
                filtered_elements_per_tracer: specializedSignatureReports.map((report) => report.filtered_element_count),
                only_gem_halo_filtered: specializedSignatureReports.every((report) => report.filtered_element_count === 1),
              },
            } : selectedSceneContract.styleId === 10 ? {
              pair_phase_locks: {
                global_route: persistentStreamReports.filter((report) => report.role === "global-route").map((report) => report.initial_phase),
                regional_write: persistentStreamReports.filter((report) => report.role === "regional-write").map((report) => report.initial_phase),
              },
              replication_direction: "left-to-right-only",
            } : selectedSceneContract.styleId === 11 ? {
              station_dwell_ring_count: auxiliaryReports.filter((report) => report.primitive === "station-dwell-ring").reduce((total, report) => total + Number(report.count || 0), 0),
              accepted_station_geometry_mutated: false,
              source_owner_decoration_count: routeOwnerDecorations.length,
              settled_owner_decoration_clone_count: settledOwnerDecorationClones.length,
              owner_decoration_source_opening_visible_count: ownerDecorationSourceOpeningVisibleCount,
              owner_decoration_clone_opening_visible_count: ownerDecorationCloneOpeningVisibleCount,
              owner_decorations: settledOwnerDecorationReports,
            } : selectedSceneContract.styleId === 12 ? {
              trace_span_reveal_count: traceSpanRevealReports.length,
              trace_span_source_count: transientTraceSpanSources.length,
              trace_span_source_opening_visible_count: traceSpanSourceOpeningVisibleCount,
              non_trace_span_node_opening_hidden_count: nonTraceSpanNodeOpeningHiddenCount,
              source_owner_decoration_count: routeOwnerDecorations.length,
              settled_owner_decoration_clone_count: settledOwnerDecorationClones.length,
              owner_decoration_source_opening_visible_count: ownerDecorationSourceOpeningVisibleCount,
              owner_decoration_clone_opening_visible_count: ownerDecorationCloneOpeningVisibleCount,
              owner_decorations: settledOwnerDecorationReports,
              status_card_blink_count: 0,
              metric_blink_count: 0,
              scanner_contained: Boolean(waterfallScannerReport),
              scanner_below_span_labels: Boolean(waterfallScannerReport?.below_span_labels),
            } : {}),
          } : {}),
          reset_range: resetRange,
          reset_opacity_samples: resetOpacitySamples,
          draw_contract: {
            source_geometry: "exact immutable edge clone",
            marker_during_draw: false,
            marker_after_arrival: true,
            easing: "linear",
          },
          persistent_stream_contract: {
            primitive: persistentStreamContract.bodyPrimitive,
            ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
              registration_bead_primitive: persistentStreamContract.beadPrimitive,
            } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
              memory_card_primitive: persistentStreamContract.cardPrimitive,
            } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
              signature_primitive: persistentStreamContract.signaturePrimitive,
            } : {
              packet_head_primitive: persistentStreamContract.headPrimitive,
            }),
            stream_count: persistentStreamReports.length,
            ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
              registration_bead_count: registrationBeadReports.length,
            } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
              memory_card_count: notionMemoryCardReports.length,
            } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
              signature_count: specializedSignatureReports.length,
            } : {
              packet_head_count: persistentPacketHeadReports.length,
            }),
            rendered_frames: [persistentStreamContract.start, renderedFrameMax],
            fade_in_frames: [persistentStreamContract.start, persistentStreamContract.start + 2],
            fade_in_factors: persistentStreamContract.fadeInFactors,
            full_opacity_frames: [persistentStreamContract.start + 2, fullOpacityEnd],
            body: {
              primitive: persistentStreamContract.bodyPrimitive,
              stroke_width: persistentStreamContract.bodyWidthDescription,
              ...(selectedSceneContract.styleId === 1 ? {
                resolved_style_1_source_stroke_width: persistentStreamContract.sourceStrokeWidth,
                resolved_style_1_stroke_width: persistentStreamContract.resolvedStrokeWidth,
              } : selectedSceneContract.styleId === 2 ? {
                resolved_style_2_source_stroke_width: persistentStreamContract.sourceStrokeWidth,
                resolved_style_2_stroke_width: persistentStreamContract.resolvedStrokeWidth,
                source_colors_in_schedule_order: persistentStreamContract.expectedSourceColors,
                semantic_colors: {
                  control: "#a855f7",
                  tool_read: "#38bdf8",
                  index_write: "#22c55e",
                  grounding_data: "#fb7185",
                  answer: "#f97316",
                },
              } : selectedSceneContract.styleId === 3 ? {
                resolved_style_3_source_stroke_width: persistentStreamContract.sourceStrokeWidth,
                resolved_style_3_stroke_width: persistentStreamContract.resolvedStrokeWidth,
                resolved_style_3_stroke_width_at_50_percent:
                  persistentStreamContract.resolvedStrokeWidth / 2,
                source_colors_in_schedule_order: persistentStreamContract.expectedSourceColors,
              } : selectedSceneContract.styleId === 4 ? {
                resolved_style_4_source_stroke_width: persistentStreamContract.sourceStrokeWidth,
                resolved_style_4_stroke_width: persistentStreamContract.resolvedStrokeWidth,
                resolved_style_4_stroke_width_at_50_percent:
                  persistentStreamContract.resolvedStrokeWidth / 2,
                source_colors_in_schedule_order: persistentStreamContract.expectedSourceColors,
                semantic_colors_in_schedule_order: persistentStreamContract.semanticColors,
              } : {
                maximum_live_width: persistentStreamContract.bodyWidthMaximum,
                resolved_widths_in_schedule_order: persistentStreamReports.map((report) => report.stroke_width),
                source_widths_in_schedule_order: persistentStreamReports.map((report) => report.source_stroke_width),
                dynamic_not_thicker_than_source: persistentStreamReports.every((report) => report.dynamic_not_thicker_than_source),
              }),
              color: persistentStreamContract.bodyColor || "inherit-source-stroke",
              opacity: persistentStreamContract.bodyOpacity,
              dash_pattern: persistentStreamContract.bodyDashPattern,
              linecap: "round",
              linejoin: "round",
              marker_free: true,
              filter_free: true,
            },
            ...(selectedSceneContract.streamMode === "blueprint-registration-bead" ? {
              registration_bead: {
                primitive: persistentStreamContract.beadPrimitive,
                shape: "circle",
                radius: persistentStreamContract.beadRadius,
                diameter_at_960px: persistentStreamContract.beadRadius * 2,
                diameter_at_50_percent: persistentStreamContract.beadRadius,
                fill: persistentStreamContract.beadFill,
                stroke: "inherit-source-stroke",
                stroke_width: persistentStreamContract.beadStrokeWidth,
                opacity: persistentStreamContract.beadOpacity,
                initial_path_distance: "stage-locked-phase",
                path_advance_per_rendered_frame: persistentStreamContract.beadAdvancePerFrame,
                direction: "source-to-target",
                wrap: "target-end-to-source-start",
                animated_attributes: ["cx", "cy", "opacity"],
                marker_free: true,
                filter_free: true,
              },
              bead_advance_per_rendered_frame: persistentStreamContract.beadAdvancePerFrame,
              stage_locks: {
                fanout: { orders: [0, 1, 2], phase: 21 },
                data_write: { orders: [0, 1, 2], phase: 28, equal_length_paths: true },
              },
            } : selectedSceneContract.streamMode === "notion-memory-card-handoff" ? {
              memory_card: {
                primitive: persistentStreamContract.cardPrimitive,
                shape: "group",
                outer_rect: {
                  ...persistentStreamContract.outerRect,
                  fill: persistentStreamContract.cardFill,
                  stroke: "semantic-memory-destination",
                  stroke_width: persistentStreamContract.cardStrokeWidth,
                },
                ink_lines: persistentStreamContract.inkLines,
                ink_stroke: "semantic-memory-destination",
                ink_stroke_width: persistentStreamContract.inkStrokeWidth,
                ink_linecap: persistentStreamContract.inkLinecap,
                ink_shape_rendering: persistentStreamContract.inkShapeRendering,
                opacity: persistentStreamContract.cardOpacity,
                semantic_colors_in_schedule_order: persistentStreamContract.semanticColors,
                initial_normalized_progress_by_stage:
                  persistentStreamContract.initialNormalizedProgress,
                initial_path_distance: "8 + progress * (pathLength - 16)",
                endpoint_clearance: persistentStreamContract.endpointClearance,
                path_advance_per_rendered_frame: persistentStreamContract.cardAdvancePerFrame,
                tangent_rotations_in_schedule_order:
                  persistentStreamContract.directionSentinels.map((sentinel) => sentinel.tangentRotation),
                direction: "source-to-target",
                wrap: "target-clearance-to-source-clearance",
                animated_attributes: ["transform", "opacity"],
                marker_free: true,
                filter_free: true,
                shadow_free: true,
                appended_below_labels_and_nodes: true,
              },
              card_advance_per_rendered_frame: persistentStreamContract.cardAdvancePerFrame,
            } : selectedSceneContract.streamMode === "specialized-live-signature" ? {
              signature: {
                primitive: persistentStreamContract.signaturePrimitive,
                signature_kind: persistentStreamContract.signatureKind,
                endpoint_clearance: persistentStreamContract.endpointClearance,
                path_advance_per_rendered_frame: persistentStreamContract.advancePerFrame,
                direction: "source-to-target",
                wrap: "target-clearance-to-source-clearance",
                tangent_aware_rotation: true,
                animated_attributes: ["transform", "opacity"],
                appended_below_labels_and_nodes: true,
                geometry_by_route: specializedSignatureReports.map((report) => ({
                  schedule_key: report.schedule_key,
                  primitive: report.primitive,
                  geometry: report.geometry,
                })),
              },
              signature_advance_per_rendered_frame: persistentStreamContract.advancePerFrame,
            } : {
              packet_head: {
                primitive: persistentStreamContract.headPrimitive,
                stroke_width: persistentStreamContract.headStrokeWidth,
                color: persistentStreamContract.headColor,
                opacity: persistentStreamContract.headOpacity,
                dash_pattern: persistentStreamContract.headDashPattern,
                dash_offset_from_body: persistentStreamContract.headLeadOffset,
                linecap: "round",
                linejoin: "round",
                marker_free: true,
                filter_free: true,
                appended_immediately_after_body: true,
              },
            }),
            dash_period: persistentStreamContract.dashPeriod,
            dash_offset_per_rendered_frame: persistentStreamContract.dashOffsetPerFrame,
            travel_user_units_per_rendered_frame: phaseStep,
            travel_pixels_per_frame_at_960px: selectedSceneContract.streamMode === "specialized-live-signature" ? persistentStreamContract.advancePerFrame : 6,
            travel_pixels_per_second_at_960px_20fps: (selectedSceneContract.streamMode === "specialized-live-signature" ? persistentStreamContract.advancePerFrame : 6) * 20,
            travel_pixels_per_frame_at_50_percent: (selectedSceneContract.streamMode === "specialized-live-signature" ? persistentStreamContract.advancePerFrame : 6) / 2,
            travel_pixels_per_second_at_50_percent_20fps: (selectedSceneContract.streamMode === "specialized-live-signature" ? persistentStreamContract.advancePerFrame : 6) * 10,
            phase_policy: persistentStreamContract.phasePolicy,
            expected_initial_phases: expectedStreamPhases,
            period_step_coprime: true,
            stream_interval_frame_count: renderedFrameMax - persistentStreamContract.start + 1,
            phase_repeat_within_stream_interval:
              renderedFrameMax - persistentStreamContract.start + 1 > persistentStreamContract.dashPeriod,
            direction: "source-to-target",
            travel_easing: "linear",
            minimum_review_scale: "50%",
            reset_range: resetRange,
            reset_opacity_samples: resetOpacitySamples,
            reset_behavior: persistentStreamContract.resetBehavior || "live rails, signatures, and scene auxiliaries keep advancing while the shared reset opacity fades to 0.03",
          },
        },
      };
    },
    {
      selectedPreset: preset,
      selectedFps: fps,
      selectedFrameCount: frameCount,
      selectedSceneContract: sceneContract,
      minimumFrameCount: MINIMUM_FRAME_COUNT,
      emptyOpeningFrame: EMPTY_OPENING_FRAME,
      resetOpacitySamples: RESET_OPACITY_SAMPLES,
    },
  );
}

async function renderFrames(arguments_) {
  const input = path.resolve(arguments_.input || "");
  const framesDirectory = path.resolve(arguments_["frames-dir"] || "");
  const preset = arguments_.preset || "";
  const sceneContract = SCENE_CONTRACTS[preset];
  const duration = Number(arguments_.duration);
  const fps = Number(arguments_.fps);
  const width = Number(arguments_.width);
  const height = Number(arguments_.height);
  if (!fs.existsSync(input) || !fs.statSync(input).isFile()) {
    throw new Error(`Input does not exist: ${input}`);
  }
  if (!fs.existsSync(framesDirectory) || !fs.statSync(framesDirectory).isDirectory()) {
    throw new Error(`Frames directory does not exist: ${framesDirectory}`);
  }
  if (
    !PRESETS.has(preset) ||
    !Number.isFinite(duration) || duration < 0.5 || duration > 20 ||
    !Number.isInteger(fps) || fps < 1 || fps > 25 ||
    !Number.isInteger(width) || width < 320 || width > 4096 ||
    !Number.isInteger(height) || height < 1 || height > 4096
  ) {
    throw new Error("Preset, duration, fps, or dimensions are invalid");
  }
  if (height > 4096 || width * height > 16777216) {
    throw new Error("Output must stay within 4096px per side and 16 megapixels");
  }

  const svg = fs.readFileSync(input, "utf8");
  const viewBoxMatch = svg.match(/viewBox="([^"]+)"/i);
  if (!viewBoxMatch) {
    throw new Error("SVG viewBox is unavailable");
  }
  const viewBox = viewBoxMatch[1].trim().split(/[\s,]+/).map(Number);
  if (viewBox.length !== 4 || viewBox.some((value) => !Number.isFinite(value))) {
    throw new Error("SVG viewBox is invalid");
  }
  const requestedFrames = duration * fps;
  const frameCount = Math.round(requestedFrames);
  if (Math.abs(requestedFrames - frameCount) > 1e-9 || frameCount > 500) {
    throw new Error("Duration multiplied by fps must be a whole number of at most 500 frames");
  }
  if (frameCount < MINIMUM_FRAME_COUNT) {
    throw new Error(`${sceneContract.name} requires at least ${MINIMUM_FRAME_COUNT} rendered frames`);
  }
  if (width * height * frameCount > 600000000) {
    throw new Error("Output dimensions multiplied by frame count may not exceed 600 million pixels");
  }

  const loaded = loadRenderer();
  const executablePath = chromeExecutable(loaded.api);
  if (!executablePath) {
    throw new Error("No compatible Chrome or Chromium executable was found");
  }
  const noSandbox = process.env.FIREWORKS_CHROME_NO_SANDBOX === "1";
  const chromeArguments = [
    "--disable-dev-shm-usage",
    "--disable-background-timer-throttling",
    "--disable-renderer-backgrounding",
    "--force-color-profile=srgb",
    "--font-render-hinting=none",
    "--hide-scrollbars",
  ];
  if (noSandbox) {
    chromeArguments.unshift("--no-sandbox", "--disable-setuid-sandbox");
  }
  const browser = await loaded.api.launch({
    headless: "new",
    executablePath,
    args: chromeArguments,
  });

  try {
    const page = await browser.newPage();
    await page.setViewport({ width, height, deviceScaleFactor: 1 });
    await page.setRequestInterception(true);
    page.on("request", (request) => {
      const url = request.url();
      if (url === "about:blank" || url.startsWith("data:") || url.startsWith("blob:")) {
        request.continue();
      } else {
        request.abort("blockedbyclient");
      }
    });
    await page.setContent(
      `<html><head><meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src data:; style-src 'unsafe-inline'">` +
      `<style>html,body{margin:0;width:${width}px;height:${height}px;overflow:hidden;background:transparent}` +
      `*{animation:none!important;transition:none!important;caret-color:transparent!important}` +
      `svg{display:block;width:${width}px!important;height:${height}px!important}</style></head>` +
      `<body><main id="diagram"></main></body></html>`,
      { waitUntil: "load" },
    );
    await page.$eval("#diagram", (container, source) => { container.innerHTML = source; }, svg);
    await page.evaluate(() => document.fonts.ready);
    const setup = await installMotionRuntime(page, preset, fps, frameCount);
    await page.evaluate(async () => {
      await document.fonts.ready;
      await new Promise((resolve) => {
        requestAnimationFrame(() => requestAnimationFrame(resolve));
      });
    });

    for (let index = 0; index < frameCount; index += 1) {
      await page.evaluate(async (frameIndex) => {
        window.__fireworksSetMotionFrame(frameIndex);
        await new Promise((resolve) => {
          requestAnimationFrame(() => requestAnimationFrame(resolve));
        });
      }, index);
      const framePath = path.join(framesDirectory, `frame-${String(index).padStart(6, "0")}.png`);
      await page.screenshot({
        path: framePath,
        type: "png",
        omitBackground: true,
        captureBeyondViewport: false,
      });
    }
    await page.close();
    return {
      ok: true,
      engine: "chromium-svg-draw-on-persistent-data-flow",
      module: loaded.module,
      resolved_module: loaded.resolvedModule,
      module_version: loaded.moduleVersion,
      chrome: executablePath,
      preset,
      duration_seconds: duration,
      fps,
      frame_count: frameCount,
      width,
      height,
      input_kind: "svg",
      effects: setup.effects,
      scene_report: setup.scene_report,
      loop_frame_policy: "integer-frame-index-centers-with-steady-state-plus-reset-boundary-repeat-scope",
      paint_barrier: "fonts-ready-plus-two-animation-frames-before-capture",
      sandbox: noSandbox ? "disabled-by-explicit-env" : "enabled",
    };
  } finally {
    await browser.close();
  }
}

async function main() {
  const arguments_ = parseArguments(process.argv.slice(2));
  const result = arguments_.probe ? probe() : await renderFrames(arguments_);
  process.stdout.write(`${JSON.stringify(result)}\n`);
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exit(1);
});
