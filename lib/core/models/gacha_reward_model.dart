class GachaReward {
  final String id;
  final String rewardName;
  final int dropRate; // 1 to 100 percentage
  final int xpReward;
  final String rarity; // 'Common', 'Rare', 'Legendary'

  const GachaReward({
    required this.id,
    required this.rewardName,
    required this.dropRate,
    required this.xpReward,
    required this.rarity,
  });
}
