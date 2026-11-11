import { describe, expect, it } from "vitest";
import {
  IGNATIAN_VALUES,
  getReflectionForDate,
  istDayNumber,
} from "../src/content/reflections.js";

describe("daily reflection", () => {
  it("gives everyone the same reflection on the same day", () => {
    const morning = new Date("2026-11-11T03:00:00Z");
    const evening = new Date("2026-11-11T15:00:00Z");

    expect(getReflectionForDate(morning)).toEqual(getReflectionForDate(evening));
  });

  it("changes at midnight in India, not midnight UTC", () => {
    const beforeMidnightIst = new Date("2026-11-11T18:29:00Z"); // 23:59 IST
    const afterMidnightIst = new Date("2026-11-11T18:31:00Z"); // 00:01 IST next day

    expect(istDayNumber(afterMidnightIst)).toBe(istDayNumber(beforeMidnightIst) + 1);
  });

  it("always returns a prompt and a known Ignatian value", () => {
    for (let i = 0; i < 60; i++) {
      const date = new Date(Date.UTC(2026, 0, 1 + i));
      const reflection = getReflectionForDate(date);

      expect(reflection.prompt.length).toBeGreaterThan(10);
      expect(IGNATIAN_VALUES).toContainEqual(reflection.value);
    }
  });
});
