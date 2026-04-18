// lib/models/worker_model.dart

enum WorkerRole { admin, technicien, videur }
enum WorkerStatus { available, busy, offline }
enum TaskBadgeType { urgent, inProgress, pending, done }

// ─────────────────────────────────────────
//  MODÈLE PRINCIPAL : USER / WORKER
// ─────────────────────────────────────────

class Worker {
  final String id;
  final String username;
  final String nomcomplet;
  final String adress;
  final String email;
  final WorkerRole role;
  final String? phone;
  final String city;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs locaux (non stockés en DB, calculés côté app)
  final WorkerStatus status;
  final int assignedMachines;
  final int tasksCompleted;
  final int? fillRate;
  final List<WorkerTask> tasks;

  const Worker({
    required this.id,
    required this.username,
    required this.nomcomplet,
    required this.adress,
    required this.email,
    required this.role,
    this.phone,
    required this.city,
    required this.createdAt,
    required this.updatedAt,
    this.status = WorkerStatus.available,
    this.assignedMachines = 0,
    this.tasksCompleted = 0,
    this.fillRate,
    this.tasks = const [],
  });

  // Initiales depuis nomcomplet
  String get initials {
    final parts = nomcomplet.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return nomcomplet.substring(0, 2).toUpperCase();
  }

  // Depuis JSON (réponse API)
  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id:              json['_id'] ?? '',
      username:        json['username'] ?? '',
      nomcomplet:      json['nomcomplet'] ?? '',
      adress:          json['adress'] ?? '',
      email:           json['email'] ?? '',
      role:            _parseRole(json['role']),
      phone:           json['phone'],
      city:            json['city'] ?? '',
      createdAt:       DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt:       DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      status:           _parseStatus(json['status']),
      assignedMachines: json['assignedMachines'] ?? 0,
      tasksCompleted:   json['tasksCompleted'] ?? 0,
      fillRate:         json['fillRate'],
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((t) => WorkerTask.fromJson(t))
          .toList(),
    );
  }

  static WorkerStatus _parseStatus(String? status) {
    if (status == null) return WorkerStatus.available;
    final s = status.toLowerCase();
    if (s == 'actif' || s == 'available' || s == 'active') {
      return WorkerStatus.available;
    } else if (s.contains('intervention') || s.contains('tournée') || s == 'busy') {
      return WorkerStatus.busy;
    } else if (s == 'offline' || s == 'hors ligne' || s == 'inactif') {
      return WorkerStatus.offline;
    }
    return WorkerStatus.available;
  }

  // Vers JSON (envoi API)
  Map<String, dynamic> toJson() {
    return {
      'username':   username,
      'nomcomplet': nomcomplet,
      'adress':     adress,
      'email':      email,
      'role':       role.name,
      'phone':      phone,
      'city':       city,
    };
  }

  // Copie avec modifications
  Worker copyWith({
    String? id,
    String? username,
    String? nomcomplet,
    String? adress,
    String? email,
    WorkerRole? role,
    String? phone,
    String? city,
    DateTime? createdAt,
    DateTime? updatedAt,
    WorkerStatus? status,
    int? assignedMachines,
    int? tasksCompleted,
    int? fillRate,
    List<WorkerTask>? tasks,
  }) {
    return Worker(
      id:               id ?? this.id,
      username:         username ?? this.username,
      nomcomplet:       nomcomplet ?? this.nomcomplet,
      adress:           adress ?? this.adress,
      email:            email ?? this.email,
      role:             role ?? this.role,
      phone:            phone ?? this.phone,
      city:             city ?? this.city,
      createdAt:        createdAt ?? this.createdAt,
      updatedAt:        updatedAt ?? this.updatedAt,
      status:           status ?? this.status,
      assignedMachines: assignedMachines ?? this.assignedMachines,
      tasksCompleted:   tasksCompleted ?? this.tasksCompleted,
      fillRate:         fillRate ?? this.fillRate,
      tasks:            tasks ?? this.tasks,
    );
  }

  static WorkerRole _parseRole(String? role) {
    switch (role) {
      case 'technicien': return WorkerRole.technicien;
      case 'videur':     return WorkerRole.videur;
      case 'admin':      return WorkerRole.admin;
      default:           return WorkerRole.technicien;
    }
  }
}

// ─────────────────────────────────────────
//  MODÈLE : TÂCHE
// ─────────────────────────────────────────

class WorkerTask {
  final String id;
  final String text;
  final String badge;
  final TaskBadgeType badgeType;
  final String? machineId;

  const WorkerTask({
    required this.id,
    required this.text,
    required this.badge,
    required this.badgeType,
    this.machineId,
  });

  factory WorkerTask.fromJson(Map<String, dynamic> json) {
    return WorkerTask(
      id:        json['_id'] ?? '',
      text:      json['text'] ?? '',
      badge:     json['badge'] ?? '',
      badgeType: _parseBadgeType(json['badgeType']),
      machineId: json['machineId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text':      text,
      'badge':     badge,
      'badgeType': badgeType.name,
      'machineId': machineId,
    };
  }

  static TaskBadgeType _parseBadgeType(String? type) {
    switch (type) {
      case 'urgent':     return TaskBadgeType.urgent;
      case 'inProgress': return TaskBadgeType.inProgress;
      case 'pending':    return TaskBadgeType.pending;
      case 'done':       return TaskBadgeType.done;
      default:           return TaskBadgeType.pending;
    }
  }
}

// ─────────────────────────────────────────
//  DONNÉES MOCK (alignées sur le schéma)
// ─────────────────────────────────────────

final List<Worker> workersMock = [
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d0',
    username: 'k.benzali',
    nomcomplet: 'Karim Benzali',
    adress: '12 Rue des Oliviers, Oran',
    email: 'k.benzali@recycle.dz',
    role: WorkerRole.technicien,
    phone: '+213 555 012 34',
    city: 'Oran',
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2025, 3, 10),
    status: WorkerStatus.busy,
    assignedMachines: 3,
    tasksCompleted: 14,
    tasks: [
      WorkerTask(id: 'T001', text: 'Réparation M-003 — Capteur IR',    badge: 'En cours', badgeType: TaskBadgeType.inProgress, machineId: 'M-003'),
      WorkerTask(id: 'T002', text: 'Vérification M-007 — Moteur servo', badge: 'Pending',  badgeType: TaskBadgeType.pending,    machineId: 'M-007'),
    ],
  ),
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d1',
    username: 'a.djouadi',
    nomcomplet: 'Amira Djouadi',
    adress: '45 Boulevard Zabana, Oran',
    email: 'a.djouadi@recycle.dz',
    role: WorkerRole.technicien,
    phone: '+213 555 098 76',
    city: 'Oran',
    createdAt: DateTime(2024, 2, 20),
    updatedAt: DateTime(2025, 3, 12),
    status: WorkerStatus.available,
    assignedMachines: 2,
    tasksCompleted: 22,
    tasks: [
      WorkerTask(id: 'T003', text: 'Remplacement caméra M-011', badge: 'Terminé', badgeType: TaskBadgeType.done, machineId: 'M-011'),
    ],
  ),
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d2',
    username: 'y.merad',
    nomcomplet: 'Youssef Merad',
    adress: '8 Rue Larbi Ben Mhidi, Oran',
    email: 'y.merad@recycle.dz',
    role: WorkerRole.videur,
    phone: '+213 555 445 67',
    city: 'Oran',
    createdAt: DateTime(2024, 3, 5),
    updatedAt: DateTime(2025, 3, 14),
    status: WorkerStatus.busy,
    assignedMachines: 4,
    tasksCompleted: 38,
    fillRate: 87,
    tasks: [
      WorkerTask(id: 'T004', text: 'Bac plastique M-001 — 87% plein', badge: 'Urgent',  badgeType: TaskBadgeType.urgent,     machineId: 'M-001'),
      WorkerTask(id: 'T005', text: 'Bac alu M-004 — 74% plein',       badge: 'À vider', badgeType: TaskBadgeType.inProgress, machineId: 'M-004'),
    ],
  ),
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d3',
    username: 'n.ouali',
    nomcomplet: 'Nassim Ouali',
    adress: '22 Cité USTO, Oran',
    email: 'n.ouali@recycle.dz',
    role: WorkerRole.videur,
    phone: '+213 555 321 09',
    city: 'Oran',
    createdAt: DateTime(2024, 4, 18),
    updatedAt: DateTime(2025, 3, 13),
    status: WorkerStatus.available,
    assignedMachines: 3,
    tasksCompleted: 51,
    fillRate: 32,
    tasks: [
      WorkerTask(id: 'T006', text: 'Vidage M-009 plastique + alu', badge: 'Terminé', badgeType: TaskBadgeType.done, machineId: 'M-009'),
    ],
  ),
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d4',
    username: 's.hadjadj',
    nomcomplet: 'Salim Hadjadj',
    adress: '3 Rue Pasteur, Oran',
    email: 's.hadjadj@recycle.dz',
    role: WorkerRole.technicien,
    phone: '+213 555 765 43',
    city: 'Oran',
    createdAt: DateTime(2024, 5, 9),
    updatedAt: DateTime(2025, 3, 11),
    status: WorkerStatus.offline,
    assignedMachines: 2,
    tasksCompleted: 9,
    tasks: [
      WorkerTask(id: 'T007', text: 'Diagnostic WiFi M-006', badge: 'Pending', badgeType: TaskBadgeType.pending, machineId: 'M-006'),
    ],
  ),
  Worker(
    id: '6650a1b2c3d4e5f6a7b8c9d5',
    username: 'r.boucherit',
    nomcomplet: 'Rania Boucherit',
    adress: '17 Avenue de l\'ALN, Oran',
    email: 'r.boucherit@recycle.dz',
    role: WorkerRole.videur,
    phone: '+213 555 234 88',
    city: 'Oran',
    createdAt: DateTime(2024, 6, 25),
    updatedAt: DateTime(2025, 3, 15),
    status: WorkerStatus.busy,
    assignedMachines: 5,
    tasksCompleted: 63,
    fillRate: 65,
    tasks: [
      WorkerTask(id: 'T008', text: 'Bac alu M-002 — 91% plein',       badge: 'Urgent',  badgeType: TaskBadgeType.urgent,     machineId: 'M-002'),
      WorkerTask(id: 'T009', text: 'Bac plastique M-005 — 65% plein', badge: 'À vider', badgeType: TaskBadgeType.inProgress, machineId: 'M-005'),
    ],
  ),
];