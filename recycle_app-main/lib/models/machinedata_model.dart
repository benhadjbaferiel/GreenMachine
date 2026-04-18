class MachineData {
  final String id;
  final String wilaya;
  final double plasticQty;
  final double aluminumQty;
  final double fillLevel; // en pourcentage

  MachineData({
    required this.id,
    required this.wilaya,
    required this.plasticQty,
    required this.aluminumQty,
    required this.fillLevel,
  });
}