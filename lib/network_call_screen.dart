import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:phone_app/constant.dart';
import 'package:phone_app/news_response.dart';

class NetworkCallScreen extends StatelessWidget {
  NetworkCallScreen({super.key});

  var client = http.Client();
  final newsController = StreamController<NewsResponse>();
  BuildContext? loaderContext;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 177, 156, 217),
        title: Text(
          'News API',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await getAllNews(context);
        },
        label: Text('CAll'),
      ),
      body: StreamBuilder<NewsResponse>(
          stream: newsController.stream,
          builder: (context, snapshot) {
            if (snapshot.data == null) {
              return SizedBox.shrink();
            }
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            final data = snapshot.data;
            return ListView.separated(
              physics: BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data?.articles[index].title ?? 'No Article',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Image.network(
                        data?.articles[index].urlToImage ?? '',
                        loadingBuilder: (context, child, loadingProgress) {
                          return loadingProgress != null
                              ? Align(
                                  alignment: Alignment.center,
                                  child: SizedBox.square(
                                    dimension: 100,
                                    child: CupertinoActivityIndicator(),
                                  ),
                                )
                              : child;
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Error Loading Image',
                              style: TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 18,
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Text(
                        data?.articles[index].description ?? 'No Description',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
              separatorBuilder: (context, index) => Divider(),
              itemCount: data?.articles.length ?? 0,
            );
          }),
    );
  }

  Future<void> getAllNews(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        loaderContext = context;
        return BackdropFilter(
          filter: ImageFilter.blur(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.deepOrange,
              ),
            ),
          ),
        );
      },
    );

    try {
      final response = await client.get(
        Uri.https(
          'newsapi.org',
          '/v2/everything',
          {
            'q': 'tesla',
            'from': '2024-07-16',
            'sortBy': 'publishedAt',
            'apiKey': Constant.API_KEY,
          },
        ),
      );

      if (response.statusCode == 200) {
        final newsResponse = newsResponseFromJson(response.body);
        newsController.add(newsResponse);
      } else {
        debugPrint('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (loaderContext != null) {
        Navigator.pop(loaderContext!);
      }
    }
  }
}
