import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/report.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class CreateReportScreen extends StatefulWidget {
  @override
  _CreateReportScreenState createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _image;
  Position? _location;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Obras Públicas',
    'Seguridad',
    'Servicios Municipales',
    'Tránsito y Vialidad',
    'Alumbrado Público',
    'Recolección de Basura',
    'Parques y Jardines',
    'Otro',
  ];

  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _checkProfileCompletion();
  }

  Future<void> _checkProfileCompletion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isProfileComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showProfileIncompleteDialog();
      });
    }
  }

  void _showProfileIncompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Perfil Incompleto'),
        content: Text(
          'Debes completar tu perfil (nombre, apellidos, teléfono, correo) '
          'para poder subir reportes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
            },
            child: Text('Completar Perfil'),
          ),
        ],
      ),
    );
  }

  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _image = File(image.path));
        await _getCurrentLocation();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al tomar la foto: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw 'Los servicios de ubicación están deshabilitados.';
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Permisos de ubicación denegados.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Los permisos de ubicación están permanentemente denegados.';
    }

    setState(() => _isLoading = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _location = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      throw 'Error al obtener la ubicación: $e';
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debes tomar una foto primero')),
      );
      return;
    }
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la ubicación')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final report = Report(
        id: _uuid.v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        imagePath: _image!.path,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      final apiService = Provider.of<ApiService>(context, listen: false);
      final databaseService =
          Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      // Intentar enviar al servidor
      final success = await apiService.submitReport(report, _image!);

      if (success) {
        // Enviar correo a la dependencia correspondiente
        await _sendEmailToDepartment(report);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reporte enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );

        _resetForm();
      } else {
        // Guardar en base de datos local para sincronización offline
        await databaseService.saveOfflineReport(report);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Reporte guardado localmente. Se enviará cuando haya conexión.'),
            backgroundColor: Colors.orange,
          ),
        );

        _resetForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar el reporte: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendEmailToDepartment(Report report) async {
    // Implementar envío de correo usando API del backend
    // Esto debería ser manejado por el servidor
    final emailData = {
      'to': _getDepartmentEmail(report.category),
      'subject': 'Nuevo Reporte Ciudadano: ${report.title}',
      'body': '''
        Se ha recibido un nuevo reporte:
        
        Categoría: ${report.category}
        Título: ${report.title}
        Descripción: ${report.description}
        Ubicación: ${report.latitude}, ${report.longitude}
        Fecha: ${report.formattedDate}
        
        Por favor atender este reporte.
      ''',
    };

    // Llamar al endpoint de email del backend
    // await apiService.sendEmail(emailData);
  }

  String _getDepartmentEmail(String category) {
    // Mapear categorías a correos departamentales
    final emailMap = {
      'Obras Públicas': 'obraspublicas@tancitaro.gob.mx',
      'Seguridad': 'seguridad@tancitaro.gob.mx',
      'Servicios Municipales': 'servicios@tancitaro.gob.mx',
      'Tránsito y Vialidad': 'transito@tancitaro.gob.mx',
      'Alumbrado Público': 'alumbrado@tancitaro.gob.mx',
      'Recolección de Basura': 'basura@tancitaro.gob.mx',
      'Parques y Jardines': 'parques@tancitaro.gob.mx',
      'Otro': 'contacto@tancitaro.gob.mx',
    };

    return emailMap[category] ?? 'contacto@tancitaro.gob.mx';
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _image = null;
      _location = null;
      _selectedCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (!authService.isProfileComplete) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Perfil Incompleto',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Completa tu perfil para poder\nsubir reportes',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile'),
              child: Text('Completar Perfil'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paso 1: Tomar foto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Paso 1: Tomar Foto',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Center(
                      child: _image == null
                          ? ElevatedButton.icon(
                              onPressed: _takePicture,
                              icon: Icon(Icons.camera_alt),
                              label: Text('Tomar Foto'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(200, 50),
                              ),
                            )
                          : Column(
                              children: [
                                Image.file(
                                  _image!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                  onPressed: _takePicture,
                                  child: Text('Tomar otra foto'),
                                ),
                              ],
                            ),
                    ),
                    if (_isLoading) ...[
                      SizedBox(height: 10),
                      LinearProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        'Obteniendo ubicación...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (_location != null) ...[
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.green),
                          SizedBox(width: 5),
                          Text(
                            'Ubicación obtenida',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Paso 2: Información del reporte
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          'Paso 2: Información del Reporte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // Categoría
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Dirección/Departamento*',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedCategory = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selecciona una categoría';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título del Reporte*',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 100,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es obligatorio';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción detallada*',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 4,
                      maxLength: 500,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Este campo es obligatorio';
                        }
                        if (value.length < 10) {
                          return 'Describe con más detalle (mínimo 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Paso 3: Vista previa y envío
            if (_image != null && _selectedCategory != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, color: Colors.blue),
                          SizedBox(width: 10),
                          Text(
                            'Paso 3: Vista Previa',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Vista previa
                      Container(
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vista previa del reporte:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[900],
                              ),
                            ),
                            SizedBox(height: 10),
                            Text('Categoría: $_selectedCategory'),
                            if (_titleController.text.isNotEmpty)
                              Text('Título: ${_titleController.text}'),
                            if (_descriptionController.text.isNotEmpty)
                              Text(
                                  'Descripción: ${_descriptionController.text}'),
                            if (_location != null)
                              Text(
                                'Ubicación: ${_location!.latitude.toStringAsFixed(6)}, '
                                '${_location!.longitude.toStringAsFixed(6)}',
                              ),
                            SizedBox(height: 10),
                            if (_image != null)
                              Image.file(
                                _image!,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // Botón de envío
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitReport,
                          icon: _isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.send),
                          label: _isSubmitting
                              ? Text('ENVIANDO...')
                              : Text('ENVIAR REPORTE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
