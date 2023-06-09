// Copyright (c) 2022 Mantano. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:dartx/dartx.dart';
import 'package:mno_navigator/epub.dart';
import 'package:mno_navigator/publication.dart';
import 'package:mno_shared/publication.dart';

abstract class ReaderCommandProcessor<T extends ReaderCommand> {
  const ReaderCommandProcessor();

  int findSpineItemIndex(T command, Publication publication);

  OpenPageRequest createOpenPageRequestForCommand(T command);
}

class GoToHrefCommandProcessor extends ReaderCommandProcessor<GoToHrefCommand> {
  const GoToHrefCommandProcessor();

  @override
  int findSpineItemIndex(GoToHrefCommand command, Publication publication) =>
      publication.pageLinks.indexWhere((spineItem) =>
          spineItem.href.removePrefix("/") == command.href.removePrefix("/"));
  @override
  OpenPageRequest createOpenPageRequestForCommand(GoToHrefCommand command) =>
      OpenPageRequest.fromElementId(command.href, command.fragment);
}

class GoToLocationCommandProcessor
    extends ReaderCommandProcessor<GoToLocationCommand> {
  const GoToLocationCommandProcessor();

  @override
  int findSpineItemIndex(GoToLocationCommand command, Publication publication) {
    ReadiumLocation readiumLocation = command.readiumLocation;
    return publication.pageLinks
        .indexWhere((spineItem) => spineItem.id == readiumLocation.idref);
  }

  @override
  OpenPageRequest createOpenPageRequestForCommand(GoToLocationCommand command) {
    ReadiumLocation readiumLocation = command.readiumLocation;
    return OpenPageRequest.fromIdrefAndCfi(
        readiumLocation.idref, readiumLocation.contentCFI);
  }
}

class GoToPageCommandProcessor extends ReaderCommandProcessor<GoToPageCommand> {
  const GoToPageCommandProcessor();

  @override
  int findSpineItemIndex(GoToPageCommand command, Publication publication) {
    Map<Link, LinkPagination> paginationInfo = publication.paginationInfo;
    int page = command.page;
    for (Link spineItem in paginationInfo.keys) {
      LinkPagination? linkPagination = paginationInfo[spineItem];
      if (linkPagination != null && linkPagination.containsPage(page)) {
        command.href = spineItem.href;
        command.percent = linkPagination.computePercent(page);
        return publication.pageLinks.indexOf(spineItem);
      }
    }
    return 0;
  }

  @override
  OpenPageRequest createOpenPageRequestForCommand(GoToPageCommand command) =>
      OpenPageRequest.fromIdrefAndPercentage(
          command.href!, command.normalizedPercent);
}
