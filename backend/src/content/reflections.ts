/**
 * Daily reflection content in the Ignatian tradition.
 *
 * The prompts are original wording built on the structure of the Examen (the
 * Jesuit practice of a short daily review). They are deliberately not quotations,
 * so nothing here is attributed to a person who did not say it.
 */
export interface IgnatianValue {
  name: string;
  meaning: string;
}

export interface Reflection {
  theme: string;
  prompt: string;
  value: IgnatianValue;
}

export const IGNATIAN_VALUES: readonly IgnatianValue[] = [
  {
    name: "Cura personalis",
    meaning: "Care for the whole person: mind, body, heart and spirit.",
  },
  {
    name: "Magis",
    meaning:
      "The more. Not doing more for its own sake, but choosing the greater good.",
  },
  {
    name: "Men and women for others",
    meaning:
      "Education that forms people who use what they learn to serve and stand with others.",
  },
  {
    name: "Finding God in all things",
    meaning:
      "Looking for meaning in ordinary moments: a lecture, a conversation, a walk across campus.",
  },
  {
    name: "Contemplatives in action",
    meaning: "Reflection and action belong together. Pause, then act well.",
  },
  {
    name: "Discernment",
    meaning:
      "Noticing what draws you toward growth and what pulls you away before you decide.",
  },
  {
    name: "Ad majorem Dei gloriam",
    meaning:
      "“For the greater glory of God”, the Jesuit motto, often shortened to AMDG.",
  },
] as const;

const PROMPTS: ReadonlyArray<Pick<Reflection, "theme" | "prompt">> = [
  {
    theme: "Gratitude",
    prompt:
      "Name three things from today you are grateful for, including one small thing you would normally overlook.",
  },
  {
    theme: "Attention",
    prompt:
      "When were you most fully present today, in class or with someone? What made that possible?",
  },
  {
    theme: "Review",
    prompt:
      "Walk through your day hour by hour. Where did you feel energised, and where did you feel drained?",
  },
  {
    theme: "Growth",
    prompt:
      "What is one thing you found difficult today, and what is it teaching you?",
  },
  {
    theme: "Others",
    prompt:
      "Who helped you today? Who might you help tomorrow, even in a small way?",
  },
  {
    theme: "Honesty",
    prompt:
      "Was there a moment you could have been kinder or more honest? What would you do differently?",
  },
  {
    theme: "Direction",
    prompt:
      "Which of tomorrow’s tasks matters most? Begin it first, and begin it calmly.",
  },
  {
    theme: "Rest",
    prompt:
      "What does your mind or body need tonight to be ready for tomorrow?",
  },
  {
    theme: "Purpose",
    prompt:
      "How does what you are studying connect to the person you want to become, and who it might help?",
  },
  {
    theme: "Friendship",
    prompt:
      "Think of a friend you have not spoken to lately. What could you say to them this week?",
  },
  {
    theme: "Courage",
    prompt:
      "What is one thing you have been putting off because it feels uncomfortable? What is the smallest first step?",
  },
  {
    theme: "Hope",
    prompt:
      "Look back on something that worried you a month ago. What happened, and what does that tell you now?",
  },
];

const DAY_MS = 24 * 60 * 60 * 1000;
const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

/** Whole days since the Unix epoch, counted in Indian Standard Time. */
export function istDayNumber(date: Date): number {
  return Math.floor((date.getTime() + IST_OFFSET_MS) / DAY_MS);
}

/** Same reflection for everyone on a given day; changes at midnight IST. */
export function getReflectionForDate(date: Date = new Date()): Reflection {
  const day = istDayNumber(date);
  const prompt = PROMPTS[day % PROMPTS.length];
  const value = IGNATIAN_VALUES[day % IGNATIAN_VALUES.length];

  return { ...prompt, value };
}
