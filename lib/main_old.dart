import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TarefasPainel(),
    ));

enum StatusTarefa { pendente, parcial, concluido }

class Tarefa {
  String titulo;
  StatusTarefa status;
  String tipo; // Dia, Semana, Mês, Ano

  Tarefa(this.titulo, this.status, this.tipo);

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'status': status.index,
        'tipo': tipo,
      };

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
        json['titulo'],
        StatusTarefa.values[json['status']],
        json['tipo'],
      );
}

class TarefasPainel extends StatefulWidget {
  @override
  _TarefasPainelState createState() => _TarefasPainelState();
}

class _TarefasPainelState extends State<TarefasPainel> {
  List<Tarefa> todasTarefas = [];
  final periodos = ['Dia', 'Semana', 'Mês', 'Ano'];
  int indicePeriodo = 0;

  String get periodoSelecionado => periodos[indicePeriodo];

  @override
  void initState() {
    super.initState();
    carregarTarefas();
  }

  Future<void> carregarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString('tarefas');
    if (dados != null) {
      final lista = jsonDecode(dados) as List;
      setState(() {
        todasTarefas = lista.map((e) => Tarefa.fromJson(e)).toList();
      });
    }
  }

  Future<void> salvarTarefas() async {
    final prefs = await SharedPreferences.getInstance();
    final dados = jsonEncode(todasTarefas.map((t) => t.toJson()).toList());
    await prefs.setString('tarefas', dados);
  }

  void mudarPeriodo(bool proximo) {
    setState(() {
      if (proximo) {
        indicePeriodo = (indicePeriodo + 1) % periodos.length;
      } else {
        indicePeriodo = (indicePeriodo - 1 + periodos.length) % periodos.length;
      }
    });
  }

  void adicionarTarefa(String titulo) {
    setState(() {
      todasTarefas.add(
        Tarefa(titulo, StatusTarefa.pendente, periodoSelecionado),
      );
    });
    salvarTarefas();
  }

  void mudarStatus(Tarefa t) {
    setState(() {
      switch (t.status) {
        case StatusTarefa.pendente:
          t.status = StatusTarefa.parcial;
          break;
        case StatusTarefa.parcial:
          t.status = StatusTarefa.concluido;
          break;
        case StatusTarefa.concluido:
          t.status = StatusTarefa.pendente;
          break;
      }
    });
    salvarTarefas();
  }

  Widget iconeStatus(StatusTarefa status) {
    switch (status) {
      case StatusTarefa.pendente:
        return Icon(Icons.crop_square_rounded, color: Colors.grey, size: 28);
      case StatusTarefa.parcial:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.crop_square_rounded,
                color: Colors.orange.withOpacity(0.4), size: 28),
            Icon(Icons.crop_square, color: Colors.orange, size: 16),
          ],
        );
      case StatusTarefa.concluido:
        return Icon(Icons.check_box_rounded, color: Colors.green, size: 28);
    }
  }

  Color corStatus(StatusTarefa status) {
    switch (status) {
      case StatusTarefa.pendente:
        return Colors.white;
      case StatusTarefa.parcial:
        return Colors.orange.shade100;
      case StatusTarefa.concluido:
        return Colors.green.shade100;
    }
  }

  List<Tarefa> get tarefasFiltradas {
    return todasTarefas
        .where((t) => t.tipo == periodoSelecionado)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFffffff), Color(0xFFe0e0e0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                /// Cabeçalho: "◀ Tarefas do Dia ▶"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, size: 28),
                      onPressed: () => mudarPeriodo(false),
                    ),
                    Text(
                      'Tarefas ${periodoSelecionado == "Semana" ? "da" : "do"} $periodoSelecionado',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown.shade800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right, size: 28),
                      onPressed: () => mudarPeriodo(true),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Lista de tarefas
                Expanded(
                  child: tarefasFiltradas.isEmpty
                      ? const Center(
                          child: Text(
                            'Nenhuma tarefa neste período.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: tarefasFiltradas.length,
                          itemBuilder: (_, i) {
                            final t = tarefasFiltradas[i];
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: corStatus(t.status),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: const Offset(1, 1),
                                  )
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      t.titulo,
                                      style: TextStyle(
                                        fontSize: 18,
                                        decoration: t.status ==
                                                StatusTarefa.concluido
                                            ? TextDecoration.lineThrough
                                            : null,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: iconeStatus(t.status),
                                    onPressed: () => mudarStatus(t),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 20),

                /// Legenda
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bolinhaLegenda(Colors.green.shade400, 'Concluído'),
                    const SizedBox(width: 16),
                    _bolinhaLegenda(Colors.orange.shade400, 'Iniciado'),
                  ],
                ),

                const SizedBox(height: 20),

                /// Botão de adicionar
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final controller = TextEditingController();
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Nova tarefa'),
                        content: TextField(
                          controller: controller,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Digite a tarefa',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (controller.text.trim().isNotEmpty) {
                                adicionarTarefa(controller.text.trim());
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Adicionar'),
                          ),
                        ],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 18),
                    backgroundColor: Colors.brown.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                  ),
                  label: Text(
                    'Nova Tarefa',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.brown.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bolinhaLegenda(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
