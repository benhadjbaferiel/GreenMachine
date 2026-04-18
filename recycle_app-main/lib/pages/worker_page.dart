import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/worker_model.dart';
import '../providers/settings_provider.dart';
import '../providers/worker_provider.dart';

class WorkerPage extends StatefulWidget {
  const WorkerPage({super.key});

  @override
  State<WorkerPage> createState() => _WorkerPageState();
}

class _WorkerPageState extends State<WorkerPage> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerProvider>().fetchWorkers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Worker> get _filtered {
    final provider = context.watch<WorkerProvider>();
    final query = _searchController.text.toLowerCase();
    return provider.workers.where((w) {
      final roleOk = _filter == 'all' ||
          (_filter == 'technicien' && w.role == WorkerRole.technicien) ||
          (_filter == 'videur' && w.role == WorkerRole.videur) ||
          (_filter == 'available' && w.status == WorkerStatus.available) ||
          (_filter == 'busy' && w.status == WorkerStatus.busy);
      final searchOk = query.isEmpty ||
          w.nomcomplet.toLowerCase().contains(query) ||
          w.city.toLowerCase().contains(query);
      return roleOk && searchOk;
    }).toList();
  }



  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final provider = context.watch<WorkerProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, settings),
            _buildStatsRow(context),
            _buildFilterBar(context),
            Expanded(
              child: provider.isLoading && provider.workers.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : provider.error != null && provider.workers.isEmpty
                      ? _buildErrorState(provider.error!)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: _filtered.isEmpty
                              ? _buildEmptyState()
                              : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 400,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _WorkerCard(
                          worker: _filtered[i],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────

  Widget _buildHeader(BuildContext context, SettingsProvider settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des travailleurs',
                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Liste des techniciens et videurs',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddWorkerDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Nouveau travailleur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A18),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ────────────────────────────────

  Widget _buildStatsRow(BuildContext context) {
    final provider = context.watch<WorkerProvider>();
    final stats = provider.dashboardStats;

    // Valeurs par défaut si les données ne sont pas encore chargées
    final totalWorkers = stats?['travailleurs']?['total'] ?? 0;
    final activeWorkers = stats?['travailleurs']?['actifs'] ?? 0;
    final totalTechs = stats?['techniciens']?['total'] ?? 0;
    final inIntervention = stats?['techniciens']?['en_intervention'] ?? 0;
    final totalVideurs = stats?['videurs']?['total'] ?? 0;
    final availableVideurs = stats?['videurs']?['disponibles'] ?? 0;
    final totalTasks = stats?['taches']?['total'] ?? 0;
    final urgentTasks = stats?['taches']?['urgentes'] ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          _StatCard(
            label: 'Total travailleurs',
            value: '$totalWorkers',
            badge: '$activeWorkers actif(s) aujourd\'hui',
            badgeColor: const Color(0xFF0C447C),
            badgeBg: const Color(0xFFE6F1FB),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Techniciens',
            value: '$totalTechs',
            badge: '$inIntervention en intervention',
            badgeColor: const Color(0xFF3C3489),
            badgeBg: const Color(0xFFEEEDFE),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Videurs',
            value: '$totalVideurs',
            badge: '$availableVideurs disponible(s)',
            badgeColor: const Color(0xFF27500A),
            badgeBg: const Color(0xFFEAF3DE),
          ),
          const SizedBox(width: 12),
          _StatCard(
            label: 'Tâches en attente',
            value: '$totalTasks',
            badge: '$urgentTasks urgente(s)',
            badgeColor: const Color(0xFF633806),
            badgeBg: const Color(0xFFFAEEDA),
          ),
        ],
      ),
    );
  }

  // ── Filtres ──────────────────────────────

  Widget _buildFilterBar(BuildContext context) {
    final filters = [
      ('all', 'Tous'),
      ('technicien', 'Techniciens'),
      ('videur', 'Videurs'),
      ('available', 'Disponibles'),
      ('busy', 'En intervention'),
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Wrap(
            spacing: 8,
            children: filters
                .map((f) => _FilterChip(
                      label: f.$2,
                      selected: _filter == f.$1,
                      onTap: () => setState(() => _filter = f.$1),
                    ))
                .toList(),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 42,
              child: TextFormField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un travailleur...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                  fillColor: Theme.of(context).cardColor,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            "Oups ! Une erreur s'est produite.",
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.read<WorkerProvider>().fetchWorkers(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text("Réessayer"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Aucun travailleur trouvé',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ──────────────────────────────

  void _showAddWorkerDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddWorkerDialog());
  }

  void _showWorkerProfile(BuildContext context, Worker w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerProfileSheet(worker: w),
    );
  }

  void _showWorkerHistory(BuildContext context, Worker w) {
    showDialog(
      context: context,
      builder: (_) => _WorkerHistoryDialog(worker: w),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : STAT CARD
// ─────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label, value, badge;
  final Color badgeColor, badgeBg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              blurRadius: 4,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: TextStyle(fontSize: 11, color: badgeColor)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : FILTER CHIP
// ─────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A1A18)
              : Theme.of(context).cardColor,
          border: Border.all(
            color: selected
                ? const Color(0xFF1A1A18)
                : Theme.of(context).dividerColor,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : WORKER CARD
// ─────────────────────────────────────────

class _WorkerCard extends StatefulWidget {
  final Worker worker;
  const _WorkerCard({required this.worker});

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard> {
  bool _isUpdating = false;

  Color get _avatarBg => widget.worker.role == WorkerRole.technicien
      ? const Color(0xFFEEEDFE)
      : const Color(0xFFE1F5EE);

  Color get _avatarFg => widget.worker.role == WorkerRole.technicien
      ? const Color(0xFF3C3489)
      : const Color(0xFF085041);

  Color get _statusColor {
    switch (widget.worker.status) {
      case WorkerStatus.available: return const Color(0xFF639922);
      case WorkerStatus.busy:      return const Color(0xFFBA7517);
      case WorkerStatus.offline:   return const Color(0xFFE24B4A);
    }
  }

  String get _statusLabel {
    switch (widget.worker.status) {
      case WorkerStatus.available: return 'Disponible';
      case WorkerStatus.busy:
        return widget.worker.role == WorkerRole.videur ? 'En tournée' : 'En intervention';
      case WorkerStatus.offline: return 'Hors ligne';
    }
  }

  Future<void> _updateStatus(BuildContext context, String newStatus) async {
    setState(() => _isUpdating = true);
    final provider = context.read<WorkerProvider>();
    final success = await provider.updateStatus(widget.worker.id, newStatus);
    
    if (success) {
      await provider.fetchWorkers(); // Refresh data
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de ${widget.worker.nomcomplet} mis à jour'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    if (mounted) setState(() => _isUpdating = false);
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Confirmer la suppression', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text('Voulez-vous vraiment supprimer ${widget.worker.nomcomplet} ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isUpdating = true);
      final provider = context.read<WorkerProvider>();
      final success = await provider.deleteWorker(widget.worker.id);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Travailleur supprimé')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : ${provider.error ?? "Impossible de supprimer"}')),
          );
        }
      }
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(context),
          const SizedBox(height: 14),
          _buildFooterButtons(context),
        ],
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 21,
          backgroundColor: _avatarBg,
          child: Text(
            widget.worker.initials,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _avatarFg),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.worker.nomcomplet,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis)),
                  ),
                  IconButton(
                    onPressed: () => _handleDelete(context),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Supprimer le travailleur',
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                widget.worker.role == WorkerRole.videur
                    ? 'Videur de bacs'
                    : 'Technicien de maintenance',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _isUpdating 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
              : PopupMenuButton<String>(
                  tooltip: 'Gérer manuellement le statut',
                  onSelected: (val) {
                    if (val == 'delete') {
                      _handleDelete(context);
                    } else {
                      _updateStatus(context, val);
                    }
                  },
                  itemBuilder: (context) => [
                    _buildStatusMenuItem('actif', 'Disponible', const Color(0xFF639922)),
                    _buildStatusMenuItem('inactif', 'Mettre hors ligne', const Color(0xFFE24B4A)),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: _statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(_statusLabel,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _avatarBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.worker.role == WorkerRole.videur ? 'Videur' : 'Technicien',
                style: TextStyle(fontSize: 11, color: _avatarFg),
              ),
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildStatusMenuItem(String value, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }



  Widget _buildFooterButtons(BuildContext context) {
    // On récupère les méthodes du State original
    final state = context.findAncestorStateOfType<_WorkerPageState>();
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => state?._showWorkerProfile(context, widget.worker),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Profil',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: () => state?._showWorkerHistory(context, widget.worker),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
              side: BorderSide(color: Theme.of(context).dividerColor),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Historique',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : TASK ITEM
// ─────────────────────────────────────────

class _TaskItem extends StatelessWidget {
  final WorkerTask task;

  const _TaskItem({required this.task});

  Color get _dotColor {
    switch (task.badgeType) {
      case TaskBadgeType.urgent:     return const Color(0xFFE24B4A);
      case TaskBadgeType.inProgress: return const Color(0xFFBA7517);
      case TaskBadgeType.pending:    return const Color(0xFF378ADD);
      case TaskBadgeType.done:       return const Color(0xFF639922);
    }
  }

  Color get _badgeBg {
    switch (task.badgeType) {
      case TaskBadgeType.urgent:     return const Color(0xFFFCEBEB);
      case TaskBadgeType.inProgress: return const Color(0xFFFAEEDA);
      case TaskBadgeType.pending:    return const Color(0xFFE6F1FB);
      case TaskBadgeType.done:       return const Color(0xFFEAF3DE);
    }
  }

  Color get _badgeFg {
    switch (task.badgeType) {
      case TaskBadgeType.urgent:     return const Color(0xFF791F1F);
      case TaskBadgeType.inProgress: return const Color(0xFF633806);
      case TaskBadgeType.pending:    return const Color(0xFF0C447C);
      case TaskBadgeType.done:       return const Color(0xFF27500A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: _dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.text,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(task.badge,
                style: TextStyle(fontSize: 11, color: _badgeFg)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  DIALOG : AJOUTER UN TRAVAILLEUR
// ─────────────────────────────────────────

class _AddWorkerDialog extends StatefulWidget {
  const _AddWorkerDialog();

  @override
  State<_AddWorkerDialog> createState() => _AddWorkerDialogState();
}

const List<String> _wilayasAlgerie = [
  "Adrar", "Chlef", "Laghouat", "Oum El Bouaghi", "Batna", "Béjaïa", "Biskra", "Béchar", "Blida", "Bouira",
  "Tamanrasset", "Tébessa", "Tlemcen", "Tiaret", "Tizi Ouzou", "Alger", "Djelfa", "Jijel", "Sétif", "Saïda",
  "Skikda", "Sidi Bel Abbès", "Annaba", "Guelma", "Constantine", "Médéa", "Mostaganem", "M'Sila", "Mascara",
  "Ouargla", "Oran", "El Bayadh", "Illizi", "Bordj Bou Arréridj", "Boumerdès", "El Tarf", "Tindouf", "Tissemsilt",
  "El Oued", "Khenchela", "Souk Ahras", "Tipaza", "Mila", "Aïn Defla", "Naâma", "Aïn Témouchent", "Ghardaïa", "Relizane"
];

class _AddWorkerDialogState extends State<_AddWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  WorkerRole _selectedRole = WorkerRole.technicien;
  String? _selectedCity;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkerProvider>();

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Nouveau travailleur',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogField(
                label: 'Nom complet', 
                controller: _nameCtrl,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Le nom est requis';
                  if (RegExp(r'[0-9]').hasMatch(v)) return 'Le nom ne peut pas contenir de chiffres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DialogField(
                label: 'Email', 
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'L\'email est requis';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(v)) return 'Format d\'email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _DialogField(
                label: 'Téléphone', 
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Le téléphone est requis';
                  if (!RegExp(r'^[0-9+ ]+$').hasMatch(v)) return 'Format invalide (chiffres uniquement)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCity,
                decoration: _dropdownDecoration('Ville / Wilaya'),
                items: _wilayasAlgerie.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _selectedCity = v),
                validator: (v) => v == null ? 'La ville est requise' : null,
                dropdownColor: Theme.of(context).cardColor,
                iconSize: 20,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('Rôle',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  const Spacer(),
                  _RoleToggle(
                    selected: _selectedRole,
                    onChanged: (r) => setState(() => _selectedRole = r),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            
            final success = await provider.addWorker({
              "username": _nameCtrl.text.toLowerCase().replaceAll(' ', '.'),
              "nomcomplet": _nameCtrl.text,
              "email": _emailCtrl.text,
              "password": "Password123", // Default password
              "phone": _phoneCtrl.text,
              "city": _selectedCity ?? "Inconnue",
              "role": _selectedRole.name,
            });

            if (mounted) {
              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Travailleur ajouté avec succès')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : ${provider.error ?? "Inconnue"}')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1A18),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Ajouter', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 1.5)),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : DIALOG FIELD
// ─────────────────────────────────────────

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;

  const _DialogField({
    required this.label, 
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Theme.of(context).dividerColor, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              BorderSide(color: Theme.of(context).dividerColor, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF10B981), width: 2),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : ROLE TOGGLE
// ─────────────────────────────────────────

class _RoleToggle extends StatelessWidget {
  final WorkerRole selected;
  final ValueChanged<WorkerRole> onChanged;

  const _RoleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoleBtn(
          label: 'Technicien',
          active: selected == WorkerRole.technicien,
          onTap: () => onChanged(WorkerRole.technicien),
        ),
        const SizedBox(width: 6),
        _RoleBtn(
          label: 'Videur',
          active: selected == WorkerRole.videur,
          onTap: () => onChanged(WorkerRole.videur),
        ),
      ],
    );
  }
}

class _RoleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoleBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1A1A18) : Theme.of(context).cardColor,
          border: Border.all(
            color: active
                ? const Color(0xFF1A1A18)
                : Theme.of(context).dividerColor,
            width: 0.8,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.grey[600])),
      ),
    );
  }
}





// ─────────────────────────────────────────
//  NEW WIDGET : WORKER HISTORY DIALOG
// ─────────────────────────────────────────

class _WorkerHistoryDialog extends StatelessWidget {
  final Worker worker;
  const _WorkerHistoryDialog({required this.worker});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkerProvider>(context, listen: false);

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Historique — ${worker.nomcomplet}',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 450,
        height: 400,
        child: FutureBuilder<Map<String, dynamic>?>(
          future: provider.fetchWorkerHistory(worker.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Chargement de l\'historique...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              );
            }

            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text("Erreur de chargement",
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("Impossible de récupérer l'historique.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              );
            }

            final data = snapshot.data!;
            final List<dynamic> history = data['history'] ?? [];
            final int total = data['total_interventions'] ?? 0;

            if (history.isEmpty) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucune activité récente',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Les tâches terminées et les interventions passées apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$total intervention(s) au total',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = history[i];
                      final dateStr = item['date'] ?? '';
                      DateTime? date;
                      String formattedDate = 'Date inconnue';
                      if (dateStr.isNotEmpty) {
                        date = DateTime.tryParse(dateStr);
                        if (date != null) {
                          formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date.toLocal());
                        }
                      }

                      final type = item['type_intervention'] ?? 'intervention';
                      final machine = item['machine_name'] ?? 'Machine inconnue';

                      IconData typeIcon = Icons.build_circle_outlined;
                      Color typeColor = const Color(0xFF3C3489);

                      if (type.toString().toLowerCase().contains('remplissage')) {
                        typeIcon = Icons.local_shipping_outlined;
                        typeColor = const Color(0xFFBA7517);
                      } else if (type.toString().toLowerCase().contains('panne')) {
                        typeIcon = Icons.error_outline;
                        typeColor = const Color(0xFFE24B4A);
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Theme.of(context).dividerColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.toString().toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: typeColor,
                                        letterSpacing: 0.5),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    machine,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: Colors.grey[600]))),
      ],
    );
  }
}

class _WorkerProfileSheet extends StatelessWidget {
  final Worker worker;
  const _WorkerProfileSheet({required this.worker});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<WorkerProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: provider.fetchWorkerProfile(worker.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            );
          }

          final profile = snapshot.data ?? {}; 
          final email = profile['email'] ?? worker.email ?? 'Non renseigné';
          final phone = profile['phone'] ?? worker.phone ?? 'N/A';
          final city = profile['city'] ?? worker.city ?? 'N/A';
          final address = profile['adress'] ?? worker.adress ?? 'Non précisée';
          
          // Nouvelles stats
          final statusLabel = profile['status_label'] ?? 'Inconnu';
          final machinesCount = profile['machines'] ?? 0;
          final tasksCount = profile['taches_completees'] ?? 0;
          final currentTasks = profile['taches_actuelles'] as List? ?? [];
          
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.green.withOpacity(0.1),
                    child: Text(worker.initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(worker.nomcomplet, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(statusLabel, style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              
              // SECTION : STATS
              Row(
                children: [
                  Expanded(child: _StatBox(label: 'Machines', value: '$machinesCount', icon: Icons.precision_manufacturing_outlined)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatBox(label: 'Tâches', value: '$tasksCount', icon: Icons.check_circle_outline)),
                ],
              ),
              const SizedBox(height: 24),

              // SECTION : MISSION ACTUELLE (Si existante)
              if (currentTasks.isNotEmpty) ...[
                const Text('⚡ MISSION ACTUELLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.05),
                    border: Border.all(color: Colors.orange.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentTasks[0]['message'] ?? 'Intervention en cours',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Machine : ${currentTasks[0]['machine']?['name'] ?? 'Inconnue'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Text('CONTACTS & LOCALISATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 12),
              _ProfileItem(icon: Icons.email_outlined, label: 'Email', value: email),
              _ProfileItem(icon: Icons.phone_outlined, label: 'Téléphone', value: phone),
              _ProfileItem(icon: Icons.location_city_outlined, label: 'Ville', value: city),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => _EditWorkerDialog(
                        worker: worker,
                        initialData: profile,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier le profil'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        }
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  WIDGET : STAT BOX (Helper)
// ─────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String label, value;
  final IconData icon;

  const _StatBox({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  DIALOG : MODIFIER UN TRAVAILLEUR
// ─────────────────────────────────────────

class _EditWorkerDialog extends StatefulWidget {
  final Worker worker;
  final Map<String, dynamic> initialData;

  const _EditWorkerDialog({required this.worker, required this.initialData});

  @override
  State<_EditWorkerDialog> createState() => _EditWorkerDialogState();
}

class _EditWorkerDialogState extends State<_EditWorkerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.worker.nomcomplet ?? '');
    _emailCtrl = TextEditingController(text: widget.initialData['email'] ?? widget.worker.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialData['phone'] ?? widget.worker.phone ?? '');
    
    // Initialisation de la ville par défaut
    _selectedCity = widget.initialData['city'] ?? widget.worker.city;
    if (_selectedCity != null && !_wilayasAlgerie.contains(_selectedCity)) {
       _selectedCity = "Alger"; // Fallback
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkerProvider>();

    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text('Modifier le profil',
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogField(
                  label: 'Nom complet',
                  controller: _nameCtrl,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Le nom est requis';
                    if (RegExp(r'[0-9]').hasMatch(v)) return 'Le nom ne peut pas contenir de chiffres';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'L\'email est requis';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Format d\'email invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                _DialogField(
                  label: 'Téléphone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Le numéro est requis';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) return 'Uniquement des chiffres';
                    if (v.length < 10) return 'Trop court (10 chiffres attendus)';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: _dropdownDecoration('Ville / Wilaya'),
                  items: _wilayasAlgerie.map((w) => DropdownMenuItem(value: w, child: Text(w, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (v) => setState(() => _selectedCity = v),
                  validator: (v) => v == null ? 'Requis' : null,
                  dropdownColor: Theme.of(context).cardColor,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final success = await provider.updateWorkerProfile(widget.worker.id, {
              "nomcomplet": _nameCtrl.text,
              "email": _emailCtrl.text,
              "phone": _phoneCtrl.text,
              "city": _selectedCity ?? "",
            });

            if (mounted) {
              if (success) {
                Navigator.pop(context); // Fermer le dialogue
                Navigator.pop(context); // Fermer le bottom sheet pour forcer le rafraîchissement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil mis à jour avec succès')),
                );
                provider.fetchWorkers(); // Rafraîchir la liste principale
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur : ${provider.error ?? "Inconnue"}')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: provider.isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.green, width: 1.5)),
    );
  }
}