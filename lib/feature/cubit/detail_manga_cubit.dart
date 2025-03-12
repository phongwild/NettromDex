import 'package:app/core/app_log.dart';
import 'package:app/feature/dio/dio_client.dart';
import 'package:app/feature/models/chapter_data_model.dart';
import 'package:app/feature/models/chapter_model.dart';
import 'package:app/feature/models/manga_model.dart';
import 'package:app/feature/utils/translate_lang.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'detail_manga_state.dart';

class DetailMangaCubit extends Cubit<DetailMangaState> with NetWorkMixin {
  DetailMangaCubit() : super(DetailMangaStateInitial());

  static const String urlManga = 'https://api.mangadex.org/manga';
  static const String urlReadChapter =
      'https://api.mangadex.org/at-home/server';
  final translateLang = TranslateLang();
  Future<void> getDetailManga(
    String idManga,
    bool isFeed, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      emit(DetailMangaStateLoading());

      // Gọi API lấy chi tiết manga
      final response = await callApiGet(endPoint: '$urlManga/$idManga');
      if (response.data['data'] == null) {
        throw Exception('Không tìm thấy dữ liệu manga');
      }

      final manga = Manga.fromJson(response.data['data']);

      if (!isFeed) {
        emit(DetailMangaStateLoaded(manga, const [], 0, ''));
        return;
      }

      // Gọi API lấy danh sách chương và chương đầu tiên
      final chaptersResponse = await callApiGet(
        endPoint: '$urlManga/$idManga/feed',
        json: {
          'offset': offset,
          'translatedLanguage[]': translateLang.language,
          'limit': 15,
          'order[chapter]': 'desc',
        },
      );

      final firstChapterResponse = await callApiGet(
        endPoint: '$urlManga/$idManga/feed',
        json: {
          'translatedLanguage[]': translateLang.language,
          'limit': 1,
          'order[chapter]': 'asc',
        },
      );

      final List<dynamic>? chaptersData = chaptersResponse.data['data'];
      final List<dynamic>? firstChapterData = firstChapterResponse.data['data'];

      if (chaptersData == null || firstChapterData == null) {
        throw Exception('Không tìm thấy danh sách chương');
      }

      // Chuyển đổi dữ liệu
      final chapters = chaptersData.map((e) => Chapter.fromJson(e)).toList();
      final String firstChapter =
          firstChapterData.isNotEmpty ? firstChapterData.first['id'] : '';

      final int total = chaptersResponse.data['total'] ?? 0;

      emit(DetailMangaStateLoaded(manga, chapters, total, firstChapter));
    } catch (e) {
      dlog(e.toString());
      emit(DetailMangaStateError(e.toString()));
    }
  }

  Future<void> getReadChapter(String idChapter) async {
    try {
      emit(DetailMangaStateLoading());
      final response = await callApiGet(endPoint: '$urlReadChapter/$idChapter');
      if (response.statusCode == 200) {
        final data = ChapterData.fromJson(response.data);
        emit(ChapterStateLoaded(data));
      } else {
        emit(DetailMangaStateError('Error: ${response.statusCode}'));
      }
    } catch (e) {
      dlog('Error: $e');
      emit(DetailMangaStateError('Error: $e'));
    }
  }
}
