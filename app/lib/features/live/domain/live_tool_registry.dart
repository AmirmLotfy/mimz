/// Typed tool name constants for all Gemini Live tool calls.
///
/// Widgets must never parse tool names from raw strings.
/// The tool bridge uses this registry to route calls to backend endpoints.
abstract final class LiveTools {
  // ─── Onboarding ─────────────────────────────────
  static const startOnboarding = 'start_onboarding';
  static const saveUserProfile = 'save_user_profile';
  static const getCurrentDistrict = 'get_current_district';

  // ─── Quiz ───────────────────────────────────────
  static const startLiveRound = 'start_live_round';
  static const gradeAnswer = 'grade_answer';
  static const requestRoundHint = 'request_round_hint';
  static const requestRoundRepeat = 'request_round_repeat';
  static const awardTerritory = 'award_territory';
  static const applyComboBonus = 'apply_combo_bonus';
  static const grantMaterials = 'grant_materials';
  static const endRound = 'end_round';

  // ─── Vision Quest ───────────────────────────────
  static const startVisionQuest = 'start_vision_quest';
  static const validateVisionResult = 'validate_vision_result';
  static const unlockStructure = 'unlock_structure';

  // ─── Social ─────────────────────────────────────
  static const joinSquadMission = 'join_squad_mission';
  static const contributeSquadProgress = 'contribute_squad_progress';
  static const getEventState = 'get_event_state';

  /// All known tool names for validation.
  static const all = <String>{
    startOnboarding,
    saveUserProfile,
    getCurrentDistrict,
    startLiveRound,
    gradeAnswer,
    requestRoundHint,
    requestRoundRepeat,
    awardTerritory,
    applyComboBonus,
    grantMaterials,
    endRound,
    startVisionQuest,
    validateVisionResult,
    unlockStructure,
    joinSquadMission,
    contributeSquadProgress,
    getEventState,
  };

  /// Returns true if the tool name is recognized.
  static bool isKnown(String name) => all.contains(name);
}
