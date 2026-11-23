import 'dart:io';
import 'package:flutter/material.dart';
import '../../database/anime_dao.dart';
import '../../models/anime.dart';
import '../../services/image_service.dart';

class AddAnimeScreen extends StatefulWidget {
  final String? initialSeason;
  final int? initialYear;

  const AddAnimeScreen({
    super.key,
    this.initialSeason,
    this.initialYear,
  });

  @override
  State<AddAnimeScreen> createState() => _AddAnimeScreenState();
}

class _AddAnimeScreenState extends State<AddAnimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _animeDao = AnimeDao();

  late final TextEditingController _titleController;
  late final TextEditingController _yearController;
  late final TextEditingController _timeController;
  late final TextEditingController _platformController;

  late String _selectedSeason;
  String? _selectedDay;
  String? _pickedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _yearController = TextEditingController(
      text: (widget.initialYear ?? DateTime.now().year).toString(),
    );
    _timeController = TextEditingController();
    _platformController = TextEditingController();

    _selectedSeason = widget.initialSeason?.toLowerCase() ?? 'fall';
    if (!Anime.validSeasons.contains(_selectedSeason)) {
      _selectedSeason = 'fall';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _timeController.dispose();
    _platformController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final imagePath = await ImageService.instance.pickImage();
    if (imagePath != null) {
      setState(() {
        _pickedImagePath = imagePath;
      });
    }
  }

  void _removePickedImage() {
    setState(() {
      _pickedImagePath = null;
    });
  }

  Future<void> _selectTime() async {
    final now = TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (pickedTime != null) {
      final hour = pickedTime.hour.toString().padLeft(2, '0');
      final minute = pickedTime.minute.toString().padLeft(2, '0');
      setState(() {
        _timeController.text = '$hour:$minute';
      });
    }
  }

  Future<void> _saveAnime() async {
    if (!_formKey.currentState!.validate()) return;

    final year = int.tryParse(_yearController.text.trim()) ?? DateTime.now().year;

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now().toIso8601String();

      // 1. Insert anime record first to obtain its auto-increment ID
      final anime = Anime(
        title: _titleController.text.trim(),
        imagePath: null,
        season: _selectedSeason,
        seasonYear: year,
        releaseDay: _selectedDay,
        releaseTime: _timeController.text.trim().isEmpty
            ? null
            : _timeController.text.trim(),
        platform: _platformController.text.trim().isEmpty
            ? null
            : _platformController.text.trim(),
        createdAt: now,
        updatedAt: now,
      );

      final animeId = await _animeDao.insertAnime(anime);

      // 2. If user picked an image, copy it with stable anime_{id} file name
      if (_pickedImagePath != null && animeId > 0) {
        final savedImagePath = await ImageService.instance.saveImageForAnime(
          animeId,
          _pickedImagePath!,
        );
        final updatedAnime = anime.copyWith(
          id: animeId,
          imagePath: savedImagePath,
        );
        await _animeDao.updateAnime(updatedAnime);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anime successfully added!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save anime: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Anime'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Image Picker Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 130,
                          height: 180,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _pickedImagePath != null
                              ? Image.file(
                                  File(_pickedImagePath!),
                                  fit: BoxFit.cover,
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      size: 44,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Poster',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: Text(_pickedImagePath == null
                                  ? 'Select Image'
                                  : 'Change Image'),
                            ),
                            if (_pickedImagePath != null) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _removePickedImage,
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Remove Image',
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter anime title',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Season and Year in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Season Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSeason,
                          decoration: const InputDecoration(
                            labelText: 'Season *',
                            prefixIcon: Icon(Icons.eco_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: Anime.validSeasons.map((s) {
                            final label =
                                s[0].toUpperCase() + s.substring(1).toLowerCase();
                            return DropdownMenuItem(
                              value: s,
                              child: Text(label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedSeason = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Season Year
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _yearController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Year *',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Year required';
                            }
                            final num = int.tryParse(val.trim());
                            if (num == null || num < 1900 || num > 2100) {
                              return 'Invalid year';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Release Day Dropdown
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedDay,
                    decoration: const InputDecoration(
                      labelText: 'Release Day',
                      prefixIcon: Icon(Icons.date_range),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ...Anime.validDays.map((day) {
                        return DropdownMenuItem<String?>(
                          value: day,
                          child: Text(day),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedDay = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Release Time
                  TextFormField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _selectTime,
                    decoration: InputDecoration(
                      labelText: 'Release Time',
                      hintText: 'Select time (e.g. 23:30)',
                      prefixIcon: const Icon(Icons.access_time),
                      suffixIcon: _timeController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _timeController.clear();
                                });
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Platform
                  TextFormField(
                    controller: _platformController,
                    decoration: const InputDecoration(
                      labelText: 'Platform',
                      hintText: 'e.g. Crunchyroll, Netflix, Bstation',
                      prefixIcon: Icon(Icons.tv),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  FilledButton(
                    onPressed: _saveAnime,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Save Anime',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
