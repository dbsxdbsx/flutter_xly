import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page4View extends GetView<Page4Controller> {
  const Page4View({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      // style: SectionBorderStyle.inset,
                      child: MyCardList(
                        onStateCreated: (state) =>
                            controller._draggableCardListState = state,
                        indexToScroll: controller.draggableAutoScroll.value &&
                                controller.draggableSelectedIndex.value != -1
                            ? controller.draggableSelectedIndex.value
                            : null,
                        itemCount: controller.draggableCards.length,
                        cardLeading: (index) =>
                            Obx(() => controller.showDragHandle.value
                                ? Icon(
                                    Icons.drag_indicator,
                                    size: 24.w,
                                    color: Colors.blue[700],
                                  )
                                : const SizedBox.shrink()),
                        cardBody: (index) => Text(
                          controller.draggableCards[index],
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        cardTrailing: (index) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MyIcon(
                              icon: Icons.edit,
                              iconColor: Colors.blue[300],
                              onPressed: () => _onEditCard(index),
                            ),
                            MyIcon(
                              icon: Icons.star_border,
                              iconColor: Colors.amber[300],
                              onPressed: () => _onStarCard(index),
                            ),
                            MyIcon(
                              icon: Icons.delete,
                              iconColor: Colors.red[300],
                              onPressed: () =>
                                  controller.deleteDraggableCard(index),
                            ),
                          ],
                        ),
                        onCardReordered: controller.reorderCards,
                        onCardPressed: (index) => _onCardPressed(
                          controller.draggableCards[index],
                          true,
                        ),
                        onSwipeDelete: (index) {
                          MyToast.show(
                              '即将删除：${controller.draggableCards[index]}');
                          controller.deleteDraggableCard(index);
                        },
                        onLoadMore: () =>
                            controller.loadMoreCards(isDraggable: true),
                        showScrollbar: true,
                        // cardMargin: EdgeInsets.symmetric(
                        //     horizontal: 6.w, vertical: 2.h),
                        cardSplashColor: (_) => Colors.black12,
                        footer: _buildFooter(controller.draggableListState),
                        // cardBorderRadius: BorderRadius.circular(48.r),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: MyGroupBox(
                      title: '不可拖动列表',
                      child: MyCardList(
                        onStateCreated: (state) =>
                            controller._staticCardListState = state,
                        indexToScroll: controller.staticAutoScroll.value &&
                                controller.staticSelectedIndex.value != -1
                            ? controller.staticSelectedIndex.value
                            : null,
                        cardLeading: (index) => Icon(
                          Icons.download_outlined,
                          size: 24.w,
                          color: Colors.green[700],
                        ),
                        cardBody: (index) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.staticCards[index],
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              '这是一个静态卡片的描述信息',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ),
                        cardTrailing: (index) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MyIcon(
                              icon: Icons.download,
                              iconColor: Colors.green[300],
                              onPressed: () => _onDownloadCard(index),
                            ),
                            MyIcon(
                              icon: Icons.copy,
                              iconColor: Colors.purple[300],
                              onPressed: () => _onCopyCard(index),
                            ),
                          ],
                        ),
                        itemCount: controller.staticCards.length,
                        showScrollbar: true,
                        cardColor: (_) => Colors.green[50]!,
                        cardMargin: (_) => EdgeInsets.symmetric(
                          horizontal: 2.h,
                          vertical: 2.h,
                        ),
                        cardPadding: (_) => EdgeInsets.only(right: 15.w),
                        onSwipeDelete: (index) {
                          MyToast.show('即将删除：${controller.staticCards[index]}');
                          controller.deleteStaticCard(index);
                        },
                        onCardPressed: (index) => _onCardPressed(
                          controller.staticCards[index],
                          false,
                        ),
                        onLoadMore: () =>
                            controller.loadMoreCards(isDraggable: false),
                        cardBorderRadius: (_) => BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 滚动控制区：两组控件对称排列
              Row(
                children: [
                  // 左侧：可拖动列表滚动控制
                  Expanded(
                    child: _buildScrollControlGroup(
                      label: '可拖动列表',
                      labelColor: Colors.blue[700]!,
                      autoScroll: controller.draggableAutoScroll,
                      selectedIndex: controller.draggableSelectedIndex,
                      itemCount: controller.draggableCards.length,
                      onScrollToIndex: controller.scrollToDraggableIndex,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  // 右侧：静态列表滚动控制
                  Expanded(
                    child: _buildScrollControlGroup(
                      label: '静态列表',
                      labelColor: Colors.green[700]!,
                      autoScroll: controller.staticAutoScroll,
                      selectedIndex: controller.staticSelectedIndex,
                      itemCount: controller.staticCards.length,
                      onScrollToIndex: controller.scrollToStaticIndex,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 功能按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MyButton(
                    onPressed: () => MyToast.show(
                        '可拖动列表项数量：${controller.draggableCards.length}'),
                    text: '可拖动列表数量',
                    size: 80.w,
                  ),
                  Obx(() => MyButton(
                        onPressed: () {
                          controller.showDragHandle.value =
                              !controller.showDragHandle.value;
                          MyToast.show(controller.showDragHandle.value
                              ? '已显示拖拽手柄'
                              : '已隐藏拖拽手柄');
                        },
                        text: controller.showDragHandle.value
                            ? '隐藏拖拽手柄'
                            : '显示拖拽手柄',
                        size: 80.w,
                      )),
                  MyButton(
                    onPressed: () => MyToast.show(
                        '静态列表项数量：${controller.staticCards.length}'),
                    text: '静态列表数量',
                    size: 80.w,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              // 导航按钮行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MyButton(
                    icon: Icons.arrow_back,
                    text: '返回第3页',
                    onPressed: () => Get.toNamed(MyRoutes.page3),
                    size: 80.w,
                  ),
                  MyButton(
                    icon: Icons.arrow_forward,
                    text: '前往第5页',
                    onPressed: () => Get.toNamed(MyRoutes.page5),
                    size: 80.w,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onCardPressed(String cardText, bool isDraggableCard) {
    String cardType = isDraggableCard ? "可拖动" : "静态";
    MyToast.show('点击了$cardType卡片：$cardText');
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
    MyToast.show('编辑卡片：${controller.draggableCards[index]}');
  }

  void _onStarCard(int index) {
    MyToast.show('收藏卡片：${controller.draggableCards[index]}');
  }

  void _onDownloadCard(int index) {
    MyToast.show('开始下载：${controller.staticCards[index]}');
  }

  void _onCopyCard(int index) {
    MyToast.show('复制链接：${controller.staticCards[index]}');
  }

  /// 构建滚动控制组件
  Widget _buildScrollControlGroup({
    required String label,
    required Color labelColor,
    required RxBool autoScroll,
    required RxInt selectedIndex,
    required int itemCount,
    required void Function(int?) onScrollToIndex,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: labelColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: labelColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标签
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          SizedBox(width: 8.w),
          // 自动滚动开关
          Obx(() => SizedBox(
                width: 24.w,
                height: 24.h,
                child: Checkbox(
                  value: autoScroll.value,
                  onChanged: (value) => autoScroll.value = value!,
                  activeColor: labelColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              )),
          SizedBox(width: 4.w),
          // 下拉选择
          Expanded(
            child: SizedBox(
              height: 36.h,
              child: Obx(() => DropdownButtonFormField<int>(
                    // ignore: deprecated_member_use, 需要动态更新值，initialValue 仅在首次渲染生效
                    value:
                        selectedIndex.value == -1 ? null : selectedIndex.value,
                    decoration: InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: labelColor.withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(
                            color: labelColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6.r),
                        borderSide: BorderSide(color: labelColor),
                      ),
                      hintText: '跳转到...',
                      hintStyle: TextStyle(fontSize: 12.sp),
                      isDense: true,
                    ),
                    style: TextStyle(fontSize: 12.sp, color: Colors.black87),
                    icon: Icon(Icons.arrow_drop_down,
                        size: 20.w, color: labelColor),
                    items: List.generate(
                      itemCount,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('第 ${index + 1} 项'),
                      ),
                    ),
                    onChanged: onScrollToIndex,
                  )),
            ),
          ),
        ],
      ),
    );
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
  final showDragHandle = true.obs;

  // 可拖动列表滚动控制
  final draggableSelectedIndex = (-1).obs;
  final draggableAutoScroll = false.obs;
  MyCardListState? _draggableCardListState;

  // 静态列表滚动控制
  final staticSelectedIndex = (-1).obs;
  final staticAutoScroll = false.obs;
  MyCardListState? _staticCardListState;

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
      MyToast.show('删除了静态卡片：$deletedCard');

      // 只为静态卡片列表加载更多卡片
      if (staticCards.length < 5 && staticListState.value.hasMoreData) {
        loadMoreCards(isDraggable: false);
      }
    }
  }

  void deleteDraggableCard(int index) {
    if (index >= 0 && index < draggableCards.length) {
      final deletedCard = draggableCards.removeAt(index);
      MyToast.show('删除了可拖动卡片：$deletedCard');

      // 只可拖动片列表加载更多卡片
      if (draggableCards.length < 5 && draggableListState.value.hasMoreData) {
        loadMoreCards(isDraggable: true);
      }
    }
  }

  /// 滚动到可拖动列表指定索引
  void scrollToDraggableIndex(int? index) {
    if (index == null) return;
    draggableSelectedIndex.value = index;

    if (draggableAutoScroll.value) {
      _forceDraggableScroll();
    }
  }

  void _forceDraggableScroll() {
    if (draggableSelectedIndex.value >= 0) {
      _draggableCardListState?.scrollToIndex(
        draggableSelectedIndex.value,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
      );
    }
  }

  /// 滚动到静态列表指定索引
  void scrollToStaticIndex(int? index) {
    if (index == null) return;
    staticSelectedIndex.value = index;

    if (staticAutoScroll.value) {
      _forceStaticScroll();
    }
  }

  void _forceStaticScroll() {
    if (staticSelectedIndex.value >= 0) {
      _staticCardListState?.scrollToIndex(
        staticSelectedIndex.value,
        duration: const Duration(milliseconds: 300),
        alignment: 0.5,
      );
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
