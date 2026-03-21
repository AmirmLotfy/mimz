import { z } from 'zod';

/**
 * Zod validation schemas for all 15 live tool call payloads.
 * The tool registry uses these to validate incoming arguments
 * before dispatching to handlers.
 */

export const StartOnboardingArgs = z.object({}).default({});
export const SaveUserProfileArgs = z.object({
  displayName: z.string().min(1).max(30).optional(),
  districtName: z.string().min(1).max(50).optional(),
  interests: z.array(z.string()).max(10).optional(),
});
export const GetCurrentDistrictArgs = z.object({}).default({});

export const StartLiveRoundArgs = z.object({
  topic: z.string().default('General'),
  difficulty: z.enum(['easy', 'dynamic', 'hard']).default('dynamic'),
  mode: z.enum(['quiz', 'sprint', 'event']).default('quiz'),
  eventId: z.string().optional(),
});
export const GradeAnswerArgs = z.object({
  answer: z.string().min(1),
  questionId: z.string().optional(),
  confidence: z.number().min(0).max(1).optional(),
  isCorrect: z.boolean().optional(),
  pointsAwarded: z.number().int().min(0).optional(),
});
export const RequestRoundHintArgs = z.object({
  roundId: z.string().optional(),
}).default({});
export const RequestRoundRepeatArgs = z.object({
  roundId: z.string().optional(),
}).default({});
export const AwardTerritoryArgs = z.object({
  sectors: z.number().int().min(1).max(5).default(1),
});
export const ApplyComboBonusArgs = z.object({
  streak: z.number().int().min(1).default(1),
  multiplier: z.number().min(1).max(5).default(1.5),
});
export const GrantMaterialsArgs = z.object({
  stone: z.number().int().min(0).max(500).default(0),
  glass: z.number().int().min(0).max(500).default(0),
  wood: z.number().int().min(0).max(500).default(0),
});
export const EndRoundArgs = z.object({
  roundId: z.string().optional(),
  totalScore: z.number().int().min(0).optional(),
  questionsAnswered: z.number().int().min(0).optional(),
});

export const StartVisionQuestArgs = z.object({
  theme: z.string().default('discovery'),
});
export const ValidateVisionResultArgs = z.object({
  questId: z.string().min(1),
  objectIdentified: z.string().min(1),
  confidence: z.number().min(0).max(1).default(0.5),
});
export const UnlockStructureArgs = z.object({
  structureId: z.string().min(1),
  structureName: z.string().optional(),
  tier: z.enum(['common', 'rare', 'master']).optional(),
});

export const JoinSquadMissionArgs = z.object({
  missionId: z.string().min(1),
});
export const ContributeSquadProgressArgs = z.object({
  missionId: z.string().min(1),
  amount: z.number().int().min(1).max(100).default(10),
});
export const GetEventStateArgs = z.object({
  eventId: z.string().min(1),
});

/** Map of tool name → Zod schema for validation. */
export const TOOL_SCHEMAS: Record<string, z.ZodType> = {
  start_onboarding: StartOnboardingArgs,
  save_user_profile: SaveUserProfileArgs,
  get_current_district: GetCurrentDistrictArgs,
  start_live_round: StartLiveRoundArgs,
  grade_answer: GradeAnswerArgs,
  request_round_hint: RequestRoundHintArgs,
  request_round_repeat: RequestRoundRepeatArgs,
  award_territory: AwardTerritoryArgs,
  apply_combo_bonus: ApplyComboBonusArgs,
  grant_materials: GrantMaterialsArgs,
  end_round: EndRoundArgs,
  start_vision_quest: StartVisionQuestArgs,
  validate_vision_result: ValidateVisionResultArgs,
  unlock_structure: UnlockStructureArgs,
  join_squad_mission: JoinSquadMissionArgs,
  contribute_squad_progress: ContributeSquadProgressArgs,
  get_event_state: GetEventStateArgs,
};

/** All known tool names. */
export const KNOWN_TOOLS = Object.keys(TOOL_SCHEMAS);
