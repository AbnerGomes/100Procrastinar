import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() => runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TarefasPainel(),
    ));

enum StatusTarefa { pendente, parcial, concluido }

class Tarefa {
  String titulo;
  StatusTarefa status;
  DateTime data;

  Tarefa(this.titulo, this.status, this.data);

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'status': status.index,
        'data': data.toIso8601String(),
      };

  factory Tarefa.fromJson(Map<String, dynamic> json) => Tarefa(
        json['titulo'],
        StatusTarefa.values[json['status']],
        DateTime.parse(json['data']),
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

  void adicionarTarefa(String titulo, DateTime data) {
    setState(() {
      todasTarefas.add(
        Tarefa(titulo, StatusTarefa.pendente, data),
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

  Color corStatus(Tarefa t) {
    if (isAtrasado(t)) {
      return Colors.red.shade300;
    }
    switch (t.status) {
      case StatusTarefa.pendente:
        return Colors.white;
      case StatusTarefa.parcial:
        return Colors.orange.shade100;
      case StatusTarefa.concluido:
        return Colors.green.shade100;
    }
  }

  bool isAtrasado(Tarefa t) {
    final hoje = DateTime.now();
    return t.data.isBefore(DateTime(hoje.year, hoje.month, hoje.day)) &&
        t.status != StatusTarefa.concluido;
  }

  List<Tarefa> get tarefasFiltradas {
    final hoje = DateTime.now();
    switch (periodoSelecionado) {
      case 'Dia':
        return todasTarefas.where((t) {
          return t.data.year == hoje.year &&
              t.data.month == hoje.month &&
              t.data.day == hoje.day;
        }).toList();
      case 'Semana':
        final inicioSemana = hoje.subtract(Duration(days: hoje.weekday % 7));
        final fimSemana = inicioSemana.add(const Duration(days: 6));
        return todasTarefas.where((t) {
          final d = t.data;
          return !d.isBefore(inicioSemana) && !d.isAfter(fimSemana);
        }).toList();
      case 'Mês':
        return todasTarefas.where((t) {
          return t.data.year == hoje.year && t.data.month == hoje.month;
        }).toList();
      case 'Ano':
        return todasTarefas.where((t) {
          return t.data.year == hoje.year;
        }).toList();
      default:
        return todasTarefas;
    }
  }

  String formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final dataAtualFormatada = DateFormat('dd/MM/yyyy').format(DateTime.now());

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_left, size: 28),
                      onPressed: () => mudarPeriodo(false),
                    ),
                    Column(
                      children: [
                        Text(
                          'Tarefas ${periodoSelecionado == "Semana" ? "da" : "do"} $periodoSelecionado',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown.shade800,
                          ),
                        ),
                        Text(
                          'Data atual: $dataAtualFormatada',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.brown.shade400,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_right, size: 28),
                      onPressed: () => mudarPeriodo(true),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

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
                                color: corStatus(t),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
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
                                        const SizedBox(height: 2),
                                        Text(
                                          formatarData(t.data),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
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

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _bolinhaLegenda(Colors.green.shade400, 'Concluído'),
                    _bolinhaLegenda(Colors.orange.shade400, 'Iniciado'),
                    _bolinhaLegenda(Colors.red.shade400, 'Atrasado'),
                  ],
                ),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final controller = TextEditingController();
                    DateTime? dataSelecionada;

                    showDialog(
                      context: context,
                      builder: (_) => StatefulBuilder(
                        builder: (context, setStateDialog) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: const Text(
                              'Nova tarefa',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: controller,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Digite a tarefa',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.calendar_today),
                                          label: Text(dataSelecionada == null
                                              ? 'Selecionar data'
                                              : DateFormat('dd/MM/yyyy')
                                                  .format(dataSelecionada!)),
                                          onPressed: () async {
                                            final hoje = DateTime.now();
                                            final selecionada = await showDatePicker(
                                              context: context,
                                              initialDate: hoje,
                                              firstDate:
                                                  hoje.subtract(const Duration(days: 365 * 5)),
                                              lastDate:
                                                  hoje.add(const Duration(days: 365 * 5)),
                                            );
                                            if (selecionada != null) {
                                              setStateDialog(() {
                                                dataSelecionada = selecionada;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (controller.text.trim().isNotEmpty &&
                                      dataSelecionada != null) {
                                    adicionarTarefa(
                                        controller.text.trim(), dataSelecionada!);
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Text('Adicionar'),
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
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
      mainAxisSize: MainAxisSize.min,
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
