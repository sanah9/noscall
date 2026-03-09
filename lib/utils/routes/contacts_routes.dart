import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:noscall/call_history/models/call_entry.dart';
import 'package:noscall/contacts/add_contact_page.dart';
import 'package:noscall/contacts/qr_scan_page.dart';
import 'package:noscall/contacts/user_detail_page.dart';
import 'package:noscall/contacts/edit_nickname_page.dart';
import 'package:noscall/contacts/edit_remark_page.dart';
import 'package:noscall/contacts/pages/group_contacts_page.dart';
import 'package:noscall/contacts/pages/contact_select_page.dart';
import 'package:noscall/utils/router_utils.dart';

/// Contact-related routes.
List<RouteBase> get contactsRoutes => [
      GoRoute(
        path: '/add-contact',
        name: 'add-contact',
        builder: (context, state) => const AddContactPage(),
      ),
      GoRoute(
        path: '/qr-scan',
        name: 'qr-scan',
        builder: (context, state) => const QRScanPage(),
      ),
      GoRoute(
        path: '/user-detail',
        name: 'user-detail',
        builder: (context, state) {
          final pubkey = getRouteParam<String>(state, 'pubkey');
          if (pubkey == null || pubkey.isEmpty) {
            return const Scaffold(
              body: Center(child: Text('User pubkey not found')),
            );
          }
          final callHistory = getRouteParam<List<CallEntry>>(state, 'callHistory');
          return UserDetailPage(pubkey: pubkey, callHistory: callHistory);
        },
      ),
      GoRoute(
        path: '/edit-nickname',
        name: 'edit-nickname',
        builder: (context, state) => buildWithRequiredParam<String>(
          state,
          'pubkey',
          'User pubkey not found',
          (pubkey) => EditNicknamePage(
            pubkey: pubkey,
            currentNickname: getRouteParam<String>(state, 'currentNickname') ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/edit-remark',
        name: 'edit-remark',
        builder: (context, state) => buildWithRequiredParam<String>(
          state,
          'pubkey',
          'User pubkey not found',
          (pubkey) => EditRemarkPage(
            pubkey: pubkey,
            currentRemark: getRouteParam<String>(state, 'currentRemark') ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/group-contacts',
        name: 'group-contacts',
        builder: (context, state) => buildWithRequiredParam<int>(
          state,
          'groupId',
          'Group ID not found',
          (groupId) => GroupContactsPage(
            groupId: groupId,
            groupName: getRouteParam<String>(state, 'groupName') ?? 'Group',
          ),
        ),
      ),
      GoRoute(
        path: '/contact-select',
        name: 'contact-select',
        builder: (context, state) => ContactSelectPage(
          excludePubKeys: getRouteParam<List<String>>(state, 'excludePubKeys'),
        ),
      ),
    ];
