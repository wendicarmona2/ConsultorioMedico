import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:apptv/Models/PacienteResponse2.dart';
import 'package:apptv/Models/CitaResponse.dart';
import 'package:apptv/Models/EspecialidadResponse.dart';
import 'package:apptv/Utils/Ambiente.dart';
import 'CitaDetailPage.dart';
import 'Login.dart';

class Home extends StatefulWidget {
  final int idUsuario;

  const Home({Key? key, required this.idUsuario}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Pacienteresponse2? paciente;
  List<Citaresponse> citas = [];
  List<EspecialidadResponse> especialidades = [];
  bool isLoading = true;

  final FocusNode listFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fnObtenerPaciente();
  }

  Future<void> fnObtenerPaciente() async {
    try {
      var response = await http.get(
        Uri.parse('${Ambiente.urlServer}/api/paciente/${widget.idUsuario}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> pacienteJson = jsonDecode(response.body);
        paciente = Pacienteresponse2.fromJson(pacienteJson);
        await fnObtenerCitas(paciente!.id);
        await fnObtenerEspecialidades();
        setState(() {});
      } else {
        throw Exception('Error al obtener los datos del paciente: ${response.statusCode}');
      }
    } catch (error) {
      print('Error obteniendo paciente: $error');
    }
  }

  Future<void> fnObtenerCitas(int idPaciente) async {
    try {
      final response = await http.get(
        Uri.parse('${Ambiente.urlServer}/api/citas/paciente/$idPaciente'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          citas = data.map((json) => Citaresponse.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Error al obtener las citas: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  Future<void> fnObtenerEspecialidades() async {
    try {
      final response = await http.get(
        Uri.parse('${Ambiente.urlServer}/api/especialidades'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          especialidades = data.map((json) => EspecialidadResponse.fromJson(json)).toList();
        });
      } else {
        throw Exception('Error al obtener las especialidades: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  String obtenerNombreEspecialidad(int idEspecialidad) {
    final especialidad = especialidades.firstWhere((e) => e.id == idEspecialidad, orElse: () => EspecialidadResponse(id: 0, nombre: 'Desconocido'));
    return especialidad.nombre;
  }

  @override
  void dispose() {
    listFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inicio",
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Color(0xFF00866E),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenido ${paciente?.nombre ?? 'Cargando...'}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                '${paciente?.correo ?? 'Cargando...'}',
                style: TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Citas',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 16),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : citas.isEmpty
                  ? const Center(child: Text('No tienes citas', style: TextStyle(fontSize: 18)))
                  : Expanded(
                child: Focus(
                  focusNode: listFocusNode,
                  child: ListView.builder(
                    itemCount: citas.length,
                    itemBuilder: (context, index) {
                      final cita = citas[index];
                      final especialidadNombre = obtenerNombreEspecialidad(cita.id_especialidad);
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          title: Text(
                            'Especialidad: $especialidadNombre',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Fecha y Hora: ${cita.FechaHora}',
                            style: TextStyle(fontSize: 18),
                          ),
                          trailing: Icon(Icons.chevron_right, color: Colors.blueAccent),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CitaDetailPage(idcita: cita.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
