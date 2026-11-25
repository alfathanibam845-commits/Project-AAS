
import 'package:flutter/material.dart';

import 'package:item_shop/pages/form_page.dart';
import 'package:item_shop/pages/homepage.dart';
import 'package:item_shop/pages/profile_account_page.dart';
import 'package:item_shop/pages/search_bar.dart';
import 'package:item_shop/pages/edit_products_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  int _homeVersion = 0;
  int _searchVersion = 0;
  int _editVersion = 0;

  bool _focusSearch = false;

  // ==========================================
  // OPEN ADD PRODUCT FORM
  // ==========================================

  Future<void> _openForm() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FormPage(),
      ),
    );

    if (created == true && mounted) {
      _refreshProductPages();
    }
  }

  // ==========================================
  // REFRESH PRODUCT PAGES
  // ==========================================

  void _refreshProductPages() {
    if (!mounted) return;

    setState(() {
      _homeVersion++;
      _searchVersion++;
      _editVersion++;
    });
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final primaryColor = colorScheme.primary;
    final surfaceColor = colorScheme.surface;
    final textColor = colorScheme.onSurface;

    final pages = [
      // HOME
      HomePage(
        key: ValueKey(_homeVersion),
      ),

      // SEARCH
      SearchPage(
        key: ValueKey(_searchVersion),
        autoFocus: _focusSearch,
      ),

      // EDIT PRODUCTS
      EditProductsPage(
        key: ValueKey(_editVersion),
        onChanged: _refreshProductPages,
      ),

      // PROFILE
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,

      // ======================================
      // APP BAR
      // ======================================

      appBar: AppBar(
        titleSpacing: 20,
        backgroundColor: colorScheme.surface,
        foregroundColor: textColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            Text(
              'Barkas',
              style: TextStyle(
                color: primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        
          
      ),

      // ======================================
      // PAGE CONTENT
      // ======================================

      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),

      // ======================================
      // ADD PRODUCT BUTTON
      // ======================================

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _openForm,
              backgroundColor: primaryColor,
              foregroundColor: colorScheme.onPrimary,
              elevation: 3,
              child: const Icon(
                Icons.add_rounded,
                size: 28,
              ),
            )
          : null,

      // ======================================
      // BOTTOM NAVIGATION
      // ======================================

      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: surfaceColor,

          indicatorColor: colorScheme.secondaryContainer,

          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return IconThemeData(
                  color: colorScheme.onSecondaryContainer,
                  size: 23,
                );
              }

              return IconThemeData(
                color: colorScheme.onSurfaceVariant,
                size: 23,
              );
            },
          ),

          labelTextStyle:
              WidgetStateProperty.resolveWith<TextStyle>(
            (states) {
              return TextStyle(
                fontSize: 12,
                fontWeight: states.contains(WidgetState.selected)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: states.contains(WidgetState.selected)
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              );
            },
          ),

          height: 76,
          elevation: 0,
        ),

        child: NavigationBar(
          selectedIndex: _selectedIndex,

          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              _focusSearch = false;
            });
          },

          backgroundColor: surfaceColor,
          indicatorColor: colorScheme.secondaryContainer,

          destinations: const [
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_rounded,
              ),
              label: 'Home',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.search_rounded,
              ),
              label: 'Search',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.edit_outlined,
              ),
              label: 'Edit',
            ),

            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
