import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page4View extends GetView<Page4Controller> {
  const Page4View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第4页', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Obx(
                () => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: MyGroupBox(
                        title: '可拖动列表',
                        style: SectionBorderStyle.inset,
                        child: MyCardList(
                          items: controller.draggableCards,
                          isDraggable: true,
                          onReorder: controller.reorderCards,
                          footer: _buildFooter(controller.draggableListState),
                          onCardPressed: _onCardPressed,
                          onLoadMore: () =>
                              controller.loadMoreCards(isDraggable: true),
                          enableBtnToDelete: true,
                          onDelete: controller.deleteDraggableCard,
                          cardColor: Colors.blue[50]!, // 为可拖动列表设置浅蓝色背景
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: MyGroupBox(
                        title: '不可拖动列表',
                        child: MyCardList(
                          items: controller.staticCards,
                          isDraggable: false,
                          footer: _buildFooter(controller.staticListState),
                          onCardPressed: _onCardPressed,
                          onLoadMore: () =>
                              controller.loadMoreCards(isDraggable: false),
                          enableSwipeToDelete: true,
                          onDelete: controller.deleteStaticCard,
                          cardHeight: 50.h,
                          fontSize: 14.sp,
                          cardPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 2.h),
                          cardMargin: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 2.h),
                          cardColor: Colors.green[50]!, // 为不可拖动列表设置浅绿色背景
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: MyButton(
              onPressed: () => Get.back(),
              text: '返回第3页',
              size: 80.w,
            ),
          ),
        ],
      ),
    );
  }

  void _onCardPressed(String cardText, bool isDraggable) {
    String cardType = isDraggable ? "可拖动" : "静态";
    toast('点击了$cardType卡片：$cardText');
  }

  Widget _buildFooter(Rx<ListState> listState) {
    return Obx(() => MyEndOfListWidget(
          isLoading: listState.value.isLoading,
          hasError: listState.value.hasError,
          hasMoreData: listState.value.hasMoreData,
          onRetry: () => controller.loadMoreCards(
            isDraggable: listState == controller.draggableListState,
          ),
          icon: Icons.sentiment_satisfied_alt,
        ));
  }
}

class Page4Controller extends GetxController {
  final draggableCards = <String>[].obs;
  final staticCards = <String>[].obs;
  final int maxCards = 30;
  final int loadIncrement = 10;
  final draggableListState = ListState().obs;
  final staticListState = ListState().obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialCards();
  }

  void _loadInitialCards() {
    draggableCards.addAll(List.generate(8, (index) => '可拖动卡片 ${index + 1}'));
    staticCards
        .addAll(List.generate(10, (index) => '静态卡片 ${index + 1}')); // 修改这里
  }

  Future<void> loadMoreCards({required bool isDraggable}) async {
    final listState = isDraggable ? draggableListState : staticListState;
    final cardList = isDraggable ? draggableCards : staticCards;

    if (listState.value.isLoading || !listState.value.hasMoreData) return;
    listState.update((val) {
      val!.isLoading = true;
      val.hasError = false;
    });

    try {
      await Future.delayed(const Duration(seconds: 2)); // 模拟网络延迟
      int currentLength = cardList.length;
      int newLength = currentLength + loadIncrement;
      if (newLength > maxCards) {
        newLength = maxCards;
        listState.update((val) => val!.hasMoreData = false);
      }
      int newItemsCount = newLength - currentLength;

      cardList.addAll(List.generate(
          newItemsCount,
          (index) =>
              '${isDraggable ? "可拖动" : "静态"}卡片 ${cardList.length + index + 1}'));
    } catch (e) {
      listState.update((val) => val!.hasError = true);
    } finally {
      listState.update((val) => val!.isLoading = false);
    }
  }

  void reorderCards(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = draggableCards.removeAt(oldIndex);
    draggableCards.insert(newIndex, item);
  }

  void deleteStaticCard(int index) {
    if (index >= 0 && index < staticCards.length) {
      final deletedCard = staticCards.removeAt(index);
      toast('删除了静态卡片：$deletedCard');

      // 只为静态卡片列表加载更多卡片
      if (staticCards.length < 5 && staticListState.value.hasMoreData) {
        loadMoreCards(isDraggable: false);
      }
    }
  }

  void deleteDraggableCard(int index) {
    if (index >= 0 && index < draggableCards.length) {
      final deletedCard = draggableCards.removeAt(index);
      toast('删除了可拖动卡片：$deletedCard');

      // 只为可拖动卡片列表加载更多卡片
      if (draggableCards.length < 5 && draggableListState.value.hasMoreData) {
        loadMoreCards(isDraggable: true);
      }
    }
  }
}

class ListState {
  bool isLoading = false;
  bool hasError = false;
  bool hasMoreData = true;

  ListState({
    this.isLoading = false,
    this.hasError = false,
    this.hasMoreData = true,
  });
}
