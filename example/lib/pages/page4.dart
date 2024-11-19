import 'package:example/main.dart';
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
                          isCardDraggable: true,
                          onSwipeDelete: (index) {
                            toast('即将删除：${controller.draggableCards[index]}');
                            controller.deleteDraggableCard(index);
                          },
                          onReorder: controller.reorderCards,
                          footer: _buildFooter(controller.draggableListState),
                          onLoadMore: () =>
                              controller.loadMoreCards(isDraggable: true),
                          cardColor: Colors.blue[50] ?? Colors.blue[100]!,
                          cardLeading: Icon(
                            Icons.drag_indicator,
                            size: 24.w,
                            color: Colors.blue[700],
                          ),
                          cardTrailing: (index) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, size: 20.w),
                                onPressed: () => _onEditCard(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(Icons.star_border, size: 20.w),
                                onPressed: () => _onStarCard(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              SizedBox(width: 8.w),
                              IconButton(
                                icon: Icon(Icons.delete, size: 20.w),
                                onPressed: () =>
                                    controller.deleteDraggableCard(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: MyGroupBox(
                        title: '不可拖动列表',
                        child: MyCardList(
                          items: controller.staticCards,
                          isCardDraggable: false,
                          onSwipeDelete: (index) {
                            toast('即将删除：${controller.staticCards[index]}');
                            controller.deleteStaticCard(index);
                          },
                          footer: _buildFooter(controller.staticListState),
                          onCardPressed: _onCardPressed,
                          onLoadMore: () =>
                              controller.loadMoreCards(isDraggable: false),
                          cardHeight: 50.h,
                          fontSize: 14.sp,
                          cardPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 2.h),
                          cardMargin: EdgeInsets.symmetric(
                              horizontal: 5.w, vertical: 2.h),
                          cardColor: Colors.green[50]!,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MyButton(
                      onPressed: () =>
                          toast('可拖动列表项数量：${controller.draggableCards.length}'),
                      text: '可拖动列表数量',
                      size: 80.w,
                    ),
                    MyButton(
                      onPressed: () =>
                          toast('静态列表项数量：${controller.staticCards.length}'),
                      text: '静态列表数量',
                      size: 80.w,
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MyButton(
                      onPressed: () => Get.back(),
                      text: '返回第3页',
                      size: 80.w,
                    ),
                    MyButton(
                      onPressed: () => Get.toNamed(Routes.page5),
                      text: '前往第5页',
                      size: 80.w,
                    ),
                  ],
                ),
              ],
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

  void _onEditCard(int index) {
    toast('编辑卡片：${controller.draggableCards[index]}');
  }

  void _onStarCard(int index) {
    toast('收藏卡片：${controller.draggableCards[index]}');
  }
}

class Page4Controller extends GetxController {
  static const int initialLoadCount = 20;
  final int maxCards = 30;
  final int loadIncrement = 10;

  final draggableCards = <String>[].obs;
  final staticCards = <String>[].obs;
  final draggableListState = ListState().obs;
  final staticListState = ListState().obs;

  @override
  void onInit() {
    super.onInit();
    _loadInitialCards();
  }

  void _loadInitialCards() {
    draggableCards.addAll(
        List.generate(initialLoadCount, (index) => '可拖动卡片 ${index + 1}'));
    staticCards.addAll(
        List.generate(initialLoadCount, (index) => '静态卡片 ${index + 1}'));

    draggableListState.update((val) {
      val!.hasMoreData = draggableCards.length < maxCards;
    });
    staticListState.update((val) {
      val!.hasMoreData = staticCards.length < maxCards;
    });
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
