/**
 * Guard name constants for state machine transitions.
 * Use these instead of string literals to prevent typos.
 *
 * @type {Object<string, string>}
 */
export const GUARD_NAMES = {
  NOT_SKIP_CLOSING: "notSkipClosing",
  SKIP_OPENING: "skipOpening",
  SKIP_CLOSING: "skipClosing",
};

/**
 * Guard functions for state machine transitions.
 * Each guard receives (previousStates, message) and returns a boolean.
 * - previousStates: Array of state strings before transition
 * - message: The message object with optional context properties
 *
 * @type {Object<string, function(string[], Object): boolean>}
 */
export const GUARDS = {
  [GUARD_NAMES.NOT_SKIP_CLOSING]: (previousStates, message) =>
    !message.skipClosing,
  [GUARD_NAMES.SKIP_OPENING]: (previousStates, message) =>
    message.skipOpening,
  [GUARD_NAMES.SKIP_CLOSING]: (previousStates, message) =>
    message.skipClosing,
};

/**
 * Sheet machines array for StateMachineGroup.
 * Matches Silk's first tw() call structure.
 */
export const SHEET_MACHINES = [
  {
    name: "staging",
    initial: "none",
    states: {
      none: {
        messages: {
          OPEN_PREPARED: "opening",
          ACTUALLY_CLOSE: {
            guard: GUARD_NAMES.NOT_SKIP_CLOSING,
            target: "closing",
          },
          ACTUALLY_STEP: "stepping",
          GO_DOWN: "going-down",
          GO_UP: "going-up",
        },
      },
      opening: { messages: { NEXT: "none" } },
      stepping: { messages: { NEXT: "none" } },
      closing: { messages: { NEXT: "none" } },
      "going-down": { messages: { NEXT: "none" } },
      "going-up": { messages: { NEXT: "none" } },
    },
  },
  {
    name: "longRunning",
    initial: "false",
    states: {
      false: { messages: { TO_TRUE: "true" } },
      true: { messages: { TO_FALSE: "false" } },
    },
  },
  {
    name: "openness",
    initial: "closed.safe-to-unmount",
    states: {
      closed: {
        initial: "safe-to-unmount",
        messages: { OPEN: "preparing-opening" },
        states: {
          "safe-to-unmount": {},
          pending: {
            messages: {
              OPEN: [
                {
                  guard: GUARD_NAMES.SKIP_OPENING,
                  target: "openness:closed.flushing-to-preparing-open",
                },
                { target: "openness:closed.flushing-to-preparing-opening" },
              ],
              FLUSH_COMPLETE: "openness:closed.safe-to-unmount",
            },
          },
          "flushing-to-preparing-opening": {
            messages: { FLUSH_COMPLETE: "openness:preparing-opening" },
          },
          "flushing-to-preparing-open": {
            messages: { FLUSH_COMPLETE: "openness:preparing-open" },
          },
        },
      },
      "preparing-opening": { messages: { PREPARED: "opening" } },
      "preparing-open": { messages: { PREPARED: "open" } },
      opening: { messages: { ANIMATION_COMPLETE: "open" } },
      open: {
        messages: {
          CLOSE: "closing",
          STEP: "open",
          SWIPE_OUT: "openness:closed.pending",
        },
        machines: [
          {
            name: "scroll",
            initial: "ended",
            states: {
              ended: {
                messages: { SCROLL_START: "ongoing" },
                machines: [
                  {
                    name: "afterPaintEffectsRun",
                    initial: "false",
                    states: {
                      false: { messages: { OCCURRED: "true" } },
                      true: { messages: { RESET: "false" } },
                    },
                  },
                ],
              },
              ongoing: { messages: { SCROLL_END: "ended" } },
            },
          },
          {
            name: "move",
            initial: "ended",
            states: {
              ended: { messages: { MOVE_START: "ongoing" } },
              ongoing: { messages: { MOVE_END: "ended" } },
            },
          },
          {
            name: "swipe",
            silentOnly: true,
            initial: "unstarted",
            states: {
              unstarted: { messages: { SWIPE_START: "ongoing" } },
              ongoing: { messages: { SWIPE_END: "ended" } },
              ended: {
                messages: { SWIPE_START: "ongoing", SWIPE_RESET: "unstarted" },
              },
            },
          },
          {
            name: "evaluateCloseMessage",
            silentOnly: true,
            initial: "false",
            states: {
              false: { messages: { CLOSE: "true" } },
              true: { messages: { CLOSE: "false" } },
            },
          },
          {
            name: "evaluateStepMessage",
            silentOnly: true,
            initial: "false",
            states: {
              false: { messages: { STEP: "true" } },
              true: { messages: { STEP: "false" } },
            },
          },
        ],
      },
      closing: { messages: { ANIMATION_COMPLETE: "openness:closed.pending" } },
    },
  },
  {
    name: "scrollContainerTouch",
    silentOnly: true,
    initial: "ended",
    states: {
      ended: { messages: { TOUCH_START: "ongoing" } },
      ongoing: { messages: { TOUCH_END: "ended" } },
    },
  },
];

/**
 * Position machines array for StateMachineGroup.
 * Matches Silk's second tw() call structure.
 */
export const POSITION_MACHINES = [
  {
    name: "active",
    initial: "false",
    states: {
      false: { messages: { TO_TRUE: "true" } },
      true: { messages: { TO_FALSE: "false" } },
    },
  },
  {
    name: "position",
    initial: "out",
    states: {
      out: {
        messages: {
          READY_TO_GO_FRONT: [
            {
              guard: GUARD_NAMES.SKIP_OPENING,
              target: "position:front.status:idle",
            },
            {
              target: "position:front.status:opening",
            },
          ],
        },
      },
      front: {
        messages: {
          GO_OUT: "position:out",
        },
        machines: [
          {
            name: "status",
            initial: "opening",
            states: {
              opening: {
                messages: {
                  NEXT: "idle",
                },
              },
              closing: {
                messages: {
                  NEXT: "position:out",
                },
              },
              idle: {
                messages: {
                  READY_TO_GO_DOWN: [
                    {
                      guard: GUARD_NAMES.SKIP_OPENING,
                      target: "position:covered.status:idle",
                    },
                    {
                      target: "position:covered.status:going-down",
                    },
                  ],
                  READY_TO_GO_OUT: "closing",
                  GO_OUT: "position:out",
                },
              },
            },
          },
        ],
      },
      covered: {
        machines: [
          {
            name: "status",
            initial: "going-down",
            states: {
              "going-down": {
                messages: {
                  NEXT: "idle",
                },
              },
              "going-up": {
                messages: {
                  NEXT: "indeterminate",
                },
              },
              indeterminate: {
                messages: {
                  GOTO_COVERED_IDLE: "idle",
                  GOTO_FRONT_IDLE: "position:front.status:idle",
                },
              },
              idle: {
                messages: {
                  READY_TO_GO_DOWN: [
                    {
                      guard: GUARD_NAMES.SKIP_OPENING,
                      target: "come-back",
                    },
                    {
                      target: "going-down",
                    },
                  ],
                  READY_TO_GO_UP: "going-up",
                  GO_UP: "indeterminate",
                  GOTO_FRONT_IDLE: "position:front.status:idle",
                },
              },
              "come-back": {
                messages: {
                  "": "idle",
                },
              },
            },
          },
        ],
      },
    },
  },
];
