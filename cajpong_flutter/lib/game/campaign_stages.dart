class CampaignStage {
  const CampaignStage({
    required this.level,
    required this.name,
    required this.minScore,
    required this.savePoints,
    required this.speedMultiplier,
    required this.pickupCooldown,
    required this.bossWave,
    required this.durabilityDamagePerSave,
    required this.pickupBurst,
  });

  final int level;
  final String name;
  final int minScore;
  final int savePoints;
  final double speedMultiplier;
  final double pickupCooldown;
  final bool bossWave;
  final int durabilityDamagePerSave;
  final int pickupBurst;
}

const List<CampaignStage> campaignStages = [
  CampaignStage(
    level: 1,
    name: 'Dockyard Warmup',
    minScore: 0,
    savePoints: 12,
    speedMultiplier: 1.0,
    pickupCooldown: 4.8,
    bossWave: false,
    durabilityDamagePerSave: 1,
    pickupBurst: 0,
  ),
  CampaignStage(
    level: 2,
    name: 'Neon Alley',
    minScore: 220,
    savePoints: 14,
    speedMultiplier: 1.08,
    pickupCooldown: 4.4,
    bossWave: false,
    durabilityDamagePerSave: 1,
    pickupBurst: 0,
  ),
  CampaignStage(
    level: 3,
    name: 'Iron Gauntlet',
    minScore: 520,
    savePoints: 16,
    speedMultiplier: 1.16,
    pickupCooldown: 3.1,
    bossWave: true,
    durabilityDamagePerSave: 2,
    pickupBurst: 2,
  ),
  CampaignStage(
    level: 4,
    name: 'Mirror Drift',
    minScore: 900,
    savePoints: 18,
    speedMultiplier: 1.24,
    pickupCooldown: 4.0,
    bossWave: false,
    durabilityDamagePerSave: 2,
    pickupBurst: 0,
  ),
  CampaignStage(
    level: 5,
    name: 'Reactor Ring',
    minScore: 1300,
    savePoints: 20,
    speedMultiplier: 1.32,
    pickupCooldown: 3.7,
    bossWave: false,
    durabilityDamagePerSave: 2,
    pickupBurst: 0,
  ),
  CampaignStage(
    level: 6,
    name: 'Comet Forge',
    minScore: 1750,
    savePoints: 22,
    speedMultiplier: 1.42,
    pickupCooldown: 2.9,
    bossWave: true,
    durabilityDamagePerSave: 2,
    pickupBurst: 3,
  ),
  CampaignStage(
    level: 7,
    name: 'Black Tide',
    minScore: 2300,
    savePoints: 24,
    speedMultiplier: 1.52,
    pickupCooldown: 3.4,
    bossWave: false,
    durabilityDamagePerSave: 3,
    pickupBurst: 0,
  ),
  CampaignStage(
    level: 8,
    name: 'Corebreaker',
    minScore: 3000,
    savePoints: 26,
    speedMultiplier: 1.62,
    pickupCooldown: 2.5,
    bossWave: true,
    durabilityDamagePerSave: 3,
    pickupBurst: 4,
  ),
];

CampaignStage campaignStageForScore(int score) {
  CampaignStage stage = campaignStages.first;
  for (final current in campaignStages) {
    if (score >= current.minScore) stage = current;
  }
  if (stage.level == campaignStages.last.level &&
      score > campaignStages.last.minScore) {
    final extraLevels = ((score - campaignStages.last.minScore) / 900).floor();
    return CampaignStage(
      level: campaignStages.last.level + extraLevels,
      name: 'Endless Rift ${extraLevels + 1}',
      minScore: campaignStages.last.minScore + (extraLevels * 900),
      savePoints: campaignStages.last.savePoints + (extraLevels * 2),
      speedMultiplier:
          (campaignStages.last.speedMultiplier + (extraLevels * 0.08))
              .clamp(1.62, 2.1),
      pickupCooldown: (campaignStages.last.pickupCooldown - (extraLevels * 0.2))
          .clamp(1.7, 2.5),
      bossWave: extraLevels.isEven,
      durabilityDamagePerSave: 3,
      pickupBurst: extraLevels.isEven ? 5 : 2,
    );
  }
  return stage;
}
