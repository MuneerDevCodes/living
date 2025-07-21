# Roles and Permissions

This document summarizes the access and management capabilities for each user role in the Sustainable Living Guide App.

---

## User Role (`role: 'user'`)

**Users can:**
- View and edit their own profile.
- Add, update, and remove items in their own cart.
- Place orders, view their own order history, and cancel their own orders.
- Create, edit, and delete their own forum posts.
- Add, edit, and delete their own recipes.
- Add and manage their own waste tracking entries.
- Add and manage their own wish list items.
- Submit new contact requests.
- Upload their own gallery items (approval may be required), view gallery.
- View challenges, products, educational content, certifications, energy tips, eco travel, and other public resources.

**Users cannot:**
- Access any `/manage-*` admin pages.
- Edit or delete other users’ content.
- Approve or moderate content.
- Manage categories, products, orders, or educational content for all users.

---

## Admin Role (`role: 'admin'`)

**Admins can:**
- Everything a user can do, plus:
- View and manage all users (edit, delete, assign roles, etc.).
- Add, edit, and delete any challenge.
- Add, edit, and delete any product.
- View and manage all orders.
- Approve, edit, and delete any gallery item or category.
- Add, edit, and delete any educational content.
- Add, edit, and delete certifications.
- View and manage all contact requests.
- Moderate (edit/delete) any forum post.
- Moderate (edit/delete) any recipe.
- Add, edit, and delete energy tips.
- Add, edit, and delete eco travel entries.
- View and manage all waste tracking entries.
- View and manage all wish list items.
- Manage categories for products, gallery, etc.
- Access admin dashboards, performance, and analytics pages.

---

## Enforcement

- Route guards in `lib/routes/routes_guard.dart` enforce access to protected and admin-only pages.
- UI elements for admin actions are only visible to admins.
- Role is fetched from the database and checked in both navigation and page logic.

---

**Keep this document updated as you add new features or roles!** 