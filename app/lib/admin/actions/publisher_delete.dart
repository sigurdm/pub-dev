// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:pub_dev/admin/actions/actions.dart';
import 'package:pub_dev/publisher/backend.dart';

final publisherDelete = AdminAction(
  name: 'publisher-delete',
  options: {'publisher': 'name of publisher to delete'},
  summary: 'Deletes publisher <publisher>.',
  description: '''
Deletes publisher <publisher>.

The publisher must have no packages. If not the operation will fail.

All member-info will be lost.

The publisher can be regenerated later (no tombstoning).
''',
  invoke: (args) async {
    final publisherId = args['publisher'];
    if (publisherId == null) {
      throw InvalidInputException('Missing `publisher` argument');
    }

    final memberCount = await publisherBackend.deleteEmptyPublisher(
      publisherId,
      allowUnlisted: true,
      onHasPackages: (packageNames) {
        throw NotAcceptableException(
          'Publisher "$publisherId" cannot be deleted, as it has package(s): '
          '${packageNames.join(', ')}.',
        );
      },
    );

    return {
      'message': 'Publisher and all members deleted.',
      'publisherId': publisherId,
      'members-count': memberCount ?? 0,
    };
  },
);
