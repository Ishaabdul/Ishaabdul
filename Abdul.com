import { pgTable, text, serial, integer, boolean, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod";

// User schema for authentication and profile info
export const users = pgTable("users", {
  id: serial("id").primaryKey(),
  username: text("username").notNull().unique(),
  password: text("password").notNull(),
  firstName: text("first_name").notNull(),
  stars: integer("stars").notNull().default(0),
  level: integer("level").notNull().default(1),
  dailyGoalMinutes: integer("daily_goal_minutes").notNull().default(10),
  dailyProgressMinutes: integer("daily_progress_minutes").notNull().default(0),
  streak: integer("streak").notNull().default(0),
});

// Operation types for the math problems
export const OperationType = {
  ADDITION: "addition",
  SUBTRACTION: "subtraction",
  MULTIPLICATION: "multiplication",
  DIVISION: "division",
  MIXED: "mixed",
} as const;

export type OperationType = typeof OperationType[keyof typeof OperationType];

// Difficulty levels for the math problems
export const DifficultyLevel = {
  EASY: "easy",
  MEDIUM: "medium",
  HARD: "hard",
} as const;

export type DifficultyLevel = typeof DifficultyLevel[keyof typeof DifficultyLevel];

// Game sessions to track user gameplay
export const gameSessions = pgTable("game_sessions", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  operation: text("operation").notNull(),
  difficulty: text("difficulty").notNull(),
  correctAnswers: integer("correct_answers").notNull(),
  incorrectAnswers: integer("incorrect_answers").notNull(),
  timeSpentSeconds: integer("time_spent_seconds").notNull(),
  starsEarned: integer("stars_earned").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

// Achievements for users to unlock
export const achievements = pgTable("achievements", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  description: text("description").notNull(),
  icon: text("icon").notNull(),
  starsReward: integer("stars_reward").notNull(),
});

// User achievements to track which achievements each user has unlocked
export const userAchievements = pgTable("user_achievements", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  achievementId: integer("achievement_id").notNull().references(() => achievements.id),
  unlockedAt: timestamp("unlocked_at").defaultNow(),
});

// Daily challenges
export const dailyChallenges = pgTable("daily_challenges", {
  id: serial("id").primaryKey(),
  description: text("description").notNull(),
  operation: text("operation").notNull(),
  difficulty: text("difficulty").notNull(),
  problemCount: integer("problem_count").notNull(),
  timeLimit: integer("time_limit").notNull(),
  starsReward: integer("stars_reward").notNull(),
  date: timestamp("date").defaultNow(),
});

// User daily challenge completions
export const userDailyChallenges = pgTable("user_daily_challenges", {
  id: serial("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id),
  challengeId: integer("challenge_id").notNull().references(() => dailyChallenges.id),
  completed: boolean("completed").notNull().default(false),
  completedAt: timestamp("completed_at"),
});

// Insert schemas with validation
export const insertUserSchema = createInsertSchema(users).pick({
  username: true,
  password: true,
  firstName: true,
});

export const insertGameSessionSchema = createInsertSchema(gameSessions).pick({
  userId: true,
  operation: true,
  difficulty: true,
  correctAnswers: true,
  incorrectAnswers: true,
  timeSpentSeconds: true,
  starsEarned: true,
});

export const updateUserProgressSchema = z.object({
  dailyProgressMinutes: z.number().min(0),
  stars: z.number().optional(),
  level: z.number().optional(),
  streak: z.number().optional(),
});

// Export types
export type InsertUser = z.infer<typeof insertUserSchema>;
export type User = typeof users.$inferSelect;
export type GameSession = typeof gameSessions.$inferSelect;
export type InsertGameSession = z.infer<typeof insertGameSessionSchema>;
export type Achievement = typeof achievements.$inferSelect;
export type UserAchievement = typeof userAchievements.$inferSelect;
export type DailyChallenge = typeof dailyChallenges.$inferSelect;
export type UserDailyChallenge = typeof userDailyChallenges.$inferSelect;
export type UpdateUserProgress = z.infer<typeof updateUserProgressSchema>;


