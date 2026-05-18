import 'package:puzzle_dot/models/curriculum_item.dart';

const Map<String, List<CurriculumItem>> curriculumData = {
  'ENT_1': [
    CurriculumItem(id: 'ENT_001', character: '1번 점', description: '점자 1번 점 위치 익히기'),
    CurriculumItem(id: 'ENT_002', character: '2번 점', description: '점자 2번 점 위치 익히기'),
    CurriculumItem(id: 'ENT_003', character: '3번 점', description: '점자 3번 점 위치 익히기'),
    CurriculumItem(id: 'ENT_004', character: '4번 점', description: '점자 4번 점 위치 익히기'),
    CurriculumItem(id: 'ENT_005', character: '5번 점', description: '점자 5번 점 위치 익히기'),
    CurriculumItem(id: 'ENT_006', character: '6번 점', description: '점자 6번 점 위치 익히기'),
  ],
  'ENT_2': [
    CurriculumItem(id: 'ENT_007', character: '1,2번 점', description: '1번+2번 점 조합'),
    CurriculumItem(id: 'ENT_008', character: '1,4번 점', description: '1번+4번 점 조합'),
    CurriculumItem(id: 'ENT_009', character: '2,5번 점', description: '2번+5번 점 조합'),
    CurriculumItem(id: 'ENT_010', character: '3,6번 점', description: '3번+6번 점 조합'),
  ],
  'BAS_1': [
    CurriculumItem(id: 'BAS_001', character: 'ㄱ', description: '기역 점자 만들기'),
    CurriculumItem(id: 'BAS_002', character: 'ㄴ', description: '니은 점자 만들기'),
    CurriculumItem(id: 'BAS_003', character: 'ㄷ', description: '디귿 점자 만들기'),
    CurriculumItem(id: 'BAS_004', character: 'ㄹ', description: '리을 점자 만들기'),
    CurriculumItem(id: 'BAS_005', character: 'ㅁ', description: '미음 점자 만들기'),
    CurriculumItem(id: 'BAS_006', character: 'ㅂ', description: '비읍 점자 만들기'),
    CurriculumItem(id: 'BAS_007', character: 'ㅅ', description: '시옷 점자 만들기'),
  ],
  'BAS_2': [
    CurriculumItem(id: 'BAS_008', character: 'ㅏ', description: '아 모음 점자'),
    CurriculumItem(id: 'BAS_009', character: 'ㅓ', description: '어 모음 점자'),
    CurriculumItem(id: 'BAS_010', character: 'ㅗ', description: '오 모음 점자'),
    CurriculumItem(id: 'BAS_011', character: 'ㅜ', description: '우 모음 점자'),
    CurriculumItem(id: 'BAS_012', character: 'ㅡ', description: '으 모음 점자'),
    CurriculumItem(id: 'BAS_013', character: 'ㅣ', description: '이 모음 점자'),
  ],
};