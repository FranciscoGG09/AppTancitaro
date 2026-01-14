import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/news.dart';
import '../services/api_service.dart';

class NewsScreen extends StatefulWidget {
  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  List<News> _news = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final news = await apiService.getNews();

      setState(() {
        _news = news;
        _isLoading = false;
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 20),
                      Text('Error al cargar noticias'),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _loadNews,
                        child: Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNews,
                  child: _news.isEmpty
                      ? Center(
                          child: Text(
                            'No hay noticias disponibles',
                            style: TextStyle(fontSize: 18),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(10),
                          itemCount: _news.length,
                          itemBuilder: (context, index) {
                            return _buildNewsCard(_news[index]);
                          },
                        ),
                ),
    );
  }

  Widget _buildNewsCard(News news) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 5),
                Text(
                  news.formattedDate,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              news.title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            if (news.imageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(news.imageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
                margin: EdgeInsets.only(bottom: 10),
              ),
            Text(
              news.content,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 10),
            if (news.attachments.isNotEmpty) ...[
              Divider(),
              Text(
                'Archivos adjuntos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8,
                children: news.attachments
                    .map((attachment) => Chip(
                          label: Text(attachment),
                          backgroundColor: Colors.blue[50],
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
