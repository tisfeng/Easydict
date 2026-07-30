# Screenshot Overlay Service Picker Design

## Goal

Make the screenshot overlay translation service picker reflect the service
configuration accurately and present available translation services clearly.
The picker selects the translation service used after Apple Vision OCR; it does
not change the OCR engine.

## Scope

- Show each eligible service with its name, icon, enabled-state dot, and
  selection checkbox.
- Treat a service as enabled when it is enabled in any of the fixed, mini, or
  main window configurations.
- Keep enabled services above disabled services while preserving the main
  window service order inside each group.
- Refresh the list when service configuration changes.
- Warn before selecting a service that is disabled in every window
  configuration.
- Apply the same translation-service eligibility rule to automatic and manual
  overlay translation.
- Preserve the current aspect-ratio correction for side-by-side results.

This change does not add an OCR engine selector, alter general service settings,
or change service configuration storage.

## Service Eligibility

The picker and translator must share one definition of an overlay translation
service. An eligible service:

1. is not Apple Dictionary or MDict;
2. is not an AI tool such as Polishing or Summary;
3. advertises translation support through `supportedQueryType()`.

Centralizing this rule prevents the picker from offering a service that the
translator later cannot use. Automatic selection still requires the candidate
to be enabled for the main query flow and to support the detected source and
target languages. A manually confirmed service may be disabled in the service
lists, but it must still pass the shared eligibility and language checks.

## State and Ordering

The main window service list supplies stable identity, display metadata, and
base order. The picker also reads the fixed and mini lists, matching services by
their unique service identifiers.

For every eligible service, the picker derives:

- `enabled = fixed.enabled || mini.enabled || main.enabled`;
- its original position in the main window list;
- its name, icon, and unique identifier.

The automatic option remains first. Other entries are sorted by enabled state,
then by their original position. The picker owns a refreshed snapshot rather
than relying only on a computed property, so SwiftUI receives an observable
state change.

## Refresh Flow

The picker reloads its snapshot when it appears and whenever
`.serviceHasUpdated` is posted. Existing service-setting actions already post
this notification after enablement, ordering, addition, removal, or relevant
configuration changes.

The refresh remains local to the picker. No polling, new persistence, or global
mutable state is introduced.

## Selection Flow

- Selecting Automatic saves the empty service identifier and closes the
  popover.
- Selecting a service enabled in any window saves its identifier and closes the
  popover.
- Selecting a service disabled in all windows presents the localized warning
  containing the selected service name.
- Cancel leaves the existing selection unchanged.
- Confirm saves the disabled service identifier and closes the popover.

If a previously saved service no longer exists or is no longer eligible, the
settings row displays Automatic and runtime selection falls back to the first
available eligible service.

## Validation

No unit tests will be added because the change is UI-focused and repository
rules exclude UI tests. Validation consists of:

1. checking the final diff for shared eligibility and notification-driven
   refresh;
2. running `git diff --check`;
3. running one `xcodebuild build` because the final Swift change exceeds the
   repository's substantive-line threshold;
4. manually checking all three window configurations, enabled-first ordering,
   live dot updates, disabled-service confirmation, selection persistence, and
   side-by-side aspect ratio.

The PR will be pushed only after manual verification succeeds. Its follow-up
comment will map the implementation to both Codex review findings and describe
the cross-window enablement rule.
