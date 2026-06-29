import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/common_controller.dart';
import 'package:get/get.dart';

abstract class CommonDataController<R, T> extends CommonController<R, T> {
  @override
  Rx<LoadingState<T>> loadingState = LoadingState<T>.loading().obs;

  @override
  Future<void> queryData([bool isRefresh = true]) async {
    if (isLoading) return;
    isLoading = true;
    debugPrint('[CommonDataController] queryData called, isRefresh: $isRefresh');
    final LoadingState<R> res = await customGetData();
    debugPrint('[CommonDataController] customGetData result: ${res.runtimeType}');
    if (res is Success<R>) {
      if (!customHandleResponse(isRefresh, res)) {
        loadingState.value = res as LoadingState<T>;
      }
    } else {
      if (isRefresh && !handleError(res is Error ? res.errMsg : null)) {
        loadingState.value = res as Error;
      }
    }
    isLoading = false;
  }

  @override
  Future<void> onReload() {
    loadingState.value = LoadingState<T>.loading();
    return super.onReload();
  }
}
