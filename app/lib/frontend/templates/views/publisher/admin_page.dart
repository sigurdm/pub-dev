// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_pub_shared/data/publisher_api.dart' as api;
import 'package:_pub_shared/search/search_form.dart';
import 'package:_pub_shared/search/tags.dart';

import '../../../../database/schema.dart' show PublisherRow;
import '../../../../package/models.dart' show Package;
import '../../../../shared/urls.dart' as urls;
import '../../../dom/dom.dart' as d;
import '../../../dom/material.dart' as material;

/// Creates the publisher admin page content.
d.Node publisherAdminPageNode({
  required PublisherRow publisher,
  required List<api.PublisherMember> members,
  required List<Package> packages,
  required bool hasMorePackages,
}) {
  final hasPackages = packages.isNotEmpty || hasMorePackages;
  final hasModeratedPackages = packages.any((p) => p.isModerated);
  final hasDeletedPackages = packages.any((p) => p.isAdminDeleted);
  return d.fragment([
    d.h2(text: 'Publisher information'),
    d.div(
      classes: ['-pub-form-textfield-row'],
      child: material.textArea(
        id: '-publisher-description',
        label: 'Description',
        rows: 5,
        cols: 60,
        value: publisher.description,
      ),
    ),
    d.div(
      classes: ['-pub-form-textfield-row'],
      child: material.textField(
        id: '-publisher-website-url',
        label: 'Website',
        value: publisher.websiteUrl,
      ),
    ),
    d.div(
      classes: ['-pub-form-textfield-row'],
      child: material.textField(
        id: '-publisher-contact-email',
        label: 'Contact email',
        value: publisher.contactEmail,
      ),
    ),
    d.div(
      classes: ['-pub-form-right-aligned'],
      child: material.button(
        id: '-publisher-update-button',
        label: 'Update',
        raised: true,
      ),
    ),
    d.h2(text: 'Members'),
    if (members.length == 1)
      d.p(
        text:
            'This publisher only has a single member. '
            'Consider adding more members to protect against losing control of the publisher.',
        classes: ['warning'],
      ),
    material.dataTable<api.PublisherMember>(
      id: '-pub-publisher-admin-members-table',
      ariaLabel: 'Members of publisher',
      columns: [
        material.DataTableColumn<api.PublisherMember>(
          headerContent: d.text('Email'),
          headerClasses: ['email-header'],
          renderCell: (api.PublisherMember m) => d.text(m.email),
        ),
        material.DataTableColumn<api.PublisherMember>(
          headerContent: d.text('Role'),
          headerClasses: ['role-header'],
          renderCell: (api.PublisherMember m) => d.text(m.role),
        ),
        material.DataTableColumn<api.PublisherMember>(
          headerContent: d.text(''),
          headerClasses: ['icons-header'],
          renderCell: (api.PublisherMember m) => d.a(
            classes: ['-pub-remove-user-button'],
            attributes: {'data-user-id': m.userId, 'data-email': m.email},
            title: 'Remove member',
            text: '×',
          ),
        ),
      ],
      entries: members,
    ),
    d.div(
      classes: ['-pub-form-right-aligned'],
      child: material.button(
        id: '-admin-add-member-button',
        label: 'Add member',
        raised: true,
      ),
    ),
    d.div(
      id: '-admin-add-member-content',
      classes: ['modal-content-hidden'],
      children: [
        d.p(
          text:
              'You can invite new members to this verified publisher. '
              'Once new members accept the invitation, they have full administrative rights, with the following abilities:',
        ),
        d.ul(
          children: [
            d.li(text: 'Transfer packages to and from this publisher'),
            d.li(
              text: 'Upload new versions of packages owned by this publisher',
            ),
            d.li(text: 'Add and remove members of this publisher'),
          ],
        ),
        d.div(
          classes: ['-pub-form-textfield-row'],
          child: material.textField(
            id: '-admin-invite-member-input',
            label: 'Email address',
          ),
        ),
      ],
    ),
    d.h2(text: 'Delete publisher'),
    if (hasPackages) ...[
      d.p(
        text:
            'This publisher cannot be deleted because it owns packages. '
            'A publisher can only be deleted when it has no packages.',
      ),
      d.p(
        children: [
          d.text('To transfer a package out of this publisher, open its '),
          d.strong(text: 'Admin'),
          d.text(
            ' page and select another verified publisher that you are a member '
            'of under ',
          ),
          d.strong(text: 'Package ownership'),
          d.text(' (you can '),
          d.a(href: urls.createPublisherUrl(), text: 'create a new publisher'),
          d.text(
            ' if needed; self-service transfer back to legacy uploader '
            'ownership is not supported — contact pub.dev support if needed).',
          ),
        ],
      ),
      if (packages.isNotEmpty) ...[
        d.p(text: 'Packages currently owned by this publisher:'),
        d.ul(
          children: [for (final package in packages) _packageListItem(package)],
        ),
      ],
      if (hasMorePackages)
        d.p(
          children: [
            d.text('And more packages. '),
            d.a(
              href: SearchForm()
                  .toggleRequiredTag(
                    PackageTags.publisherTag(publisher.publisherId),
                  )
                  .toggleRequiredTag(PackageTags.showHidden)
                  .toSearchLink(),
              rel: 'nofollow',
              text: 'View all packages owned by this publisher',
            ),
            d.text('.'),
          ],
        ),
      if (hasModeratedPackages && hasDeletedPackages)
        d.p(
          text:
              'Moderated or deleted packages cannot be transferred by '
              'publisher members. Deleted packages are permanently purged '
              'after about two months; for moderated packages, appeal the '
              'moderation decision or contact pub.dev support.',
        )
      else if (hasModeratedPackages)
        d.p(
          text:
              'Moderated packages cannot be transferred by publisher members. '
              'Appeal the moderation decision or contact pub.dev support if '
              'you need assistance.',
        )
      else if (hasDeletedPackages)
        d.p(
          text:
              'Deleted packages cannot be transferred by publisher members '
              'and are permanently purged after about two months. Contact '
              'pub.dev support if you need assistance.',
        ),
    ] else
      d.p(
        text:
            'Deleting this publisher will permanently remove it and all its '
            'member associations.',
      ),
    d.div(
      classes: ['-pub-form-right-aligned'],
      child: material.button(
        id: '-publisher-delete-button',
        classes: ['pub-button-danger'],
        label: 'Delete publisher',
        raised: true,
        disabled: hasPackages,
      ),
    ),
  ]);
}

d.Node _packageListItem(Package package) {
  final name = package.name!;
  final statuses = <String>[
    if (package.isModerated) 'moderated',
    if (package.isAdminDeleted) 'deleted',
    if (package.isVisible && package.isDiscontinued) 'discontinued',
    if (package.isVisible && package.isUnlisted) 'unlisted',
  ];
  final statusSuffix = statuses.isEmpty ? '' : ' (${statuses.join(', ')})';
  if (package.isNotVisible) {
    return d.li(
      children: [
        d.code(text: name),
        if (statusSuffix.isNotEmpty) d.text(statusSuffix),
      ],
    );
  }
  return d.li(
    children: [
      d.a(href: urls.pkgPageUrl(name), text: name),
      if (statusSuffix.isNotEmpty) d.text(statusSuffix),
      d.text(' — '),
      d.a(href: urls.pkgAdminUrl(name), text: 'Admin'),
    ],
  );
}
