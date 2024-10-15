import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page4Controller extends GetxController {
  final cards = <String>[].obs;
  final ScrollController scrollController = ScrollController();
  final int maxCards = 30;
  final int loadIncrement = 10;
  final isLoading = false.obs;
  final hasError = false.obs;
  final hasMoreData = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialCards();
    _setupScrollListener();
  }

  void _loadInitialCards() {
    cards.addAll(List.generate(15, (index) => '卡片 ${index + 1}'));
  }

  void _setupScrollListener() {
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          scrollController.position.maxScrollExtent - 100) {
        if (hasMoreData.value && !isLoading.value && !hasError.value) {
          loadMoreCards();
        }
      }
    });
  }

  Future<bool> loadMoreCards() async {
    if (isLoading.value || !hasMoreData.value) return false;
    isLoading.value = true;
    hasError.value = false;

    try {
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络延迟
      int currentLength = cards.length;
      int newLength = currentLength + loadIncrement;
      if (newLength > maxCards) {
        newLength = maxCards;
        hasMoreData.value = false;
      }
      cards.addAll(List.generate(newLength - currentLength,
          (index) => '卡片 ${currentLength + index + 1}'));
      return true;
    } catch (e) {
      hasError.value = true;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = cards.removeAt(oldIndex);
    cards.insert(newIndex, item);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}

class Page4View extends StatelessWidget {
  const Page4View({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Page4Controller>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: Text('可拖动卡片列表', style: TextStyle(fontSize: 18.sp)),
        ),
        body: Obx(
          () => Scrollbar(
            controller: controller.scrollController,
            child: CustomScrollView(
              controller: controller.scrollController,
              slivers: [
                SliverReorderableList(
                  itemCount: controller.cards.length,
                  itemBuilder: (context, index) {
                    final card = controller.cards[index];
                    return Card(
                      key: ValueKey(card),
                      elevation: 2,
                      margin:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        child: Text(card, style: TextStyle(fontSize: 16.sp)),
                      ),
                    );
                  },
                  onReorder: controller.reorderCards,
                ),
                MyEndOfListWidget(
                  isLoading: controller.isLoading.value,
                  hasError: controller.hasError.value,
                  hasMoreData: controller.hasMoreData.value,
                  onRetry: controller.loadMoreCards,
                  useSliver: true,
                  icon: Icons.sentiment_satisfied_alt,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
