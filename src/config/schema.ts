
import {
  mysqlTable,
  int,
  varchar,
  text,
  decimal,
  timestamp,
  mysqlEnum,
} from "drizzle-orm/mysql-core";

// ====================
// USERS
// ====================

export const usersTable = mysqlTable("users", {
  id: int("id").autoincrement().primaryKey(),

  username: varchar("username", {
    length: 100,
  }).notNull(),

  email: varchar("email", {
    length: 150,
  })
    .notNull()
    .unique(),

  password: varchar("password", {
    length: 255,
  }).notNull(),

  // ROLE: ADMIN / USER
  role: mysqlEnum("role", ["admin", "user"])
    .notNull()
    .default("user"),

  profileImage: varchar("profile_image", {
    length: 500,
  }),

  profileImagePublicId: varchar("profile_image_public_id", {
    length: 255,
  }),

  bannerImage: varchar("banner_image", {
    length: 500,
  }),

  bannerImagePublicId: varchar("banner_image_public_id", {
    length: 255,
  }),

  createdAt: timestamp("created_at").defaultNow(),

  updatedAt: timestamp("updated_at")
    .defaultNow()
    .onUpdateNow(),
});

// ====================
// PRODUCTS
// ====================

export const productsTable = mysqlTable("products", {
  id: int("id").autoincrement().primaryKey(),

  name: varchar("name", {
    length: 150,
  }).notNull(),

  category: varchar("category", {
    length: 100,
  }).notNull(),

  price: decimal("price", {
    precision: 15,
    scale: 2,
  }).notNull(),

  stock: int("stock").notNull().default(0),

  description: text("description"),

  imageUrl: varchar("image_url", {
    length: 500,
  }).notNull(),

  imagePublicId: varchar("image_public_id", {
    length: 255,
  }),

  createdAt: timestamp("created_at").defaultNow(),

  updatedAt: timestamp("updated_at")
    .defaultNow()
    .onUpdateNow(),
});

// ====================
// CATEGORIES
// ====================

export const categoriesTable = mysqlTable("categories", {
  id: int("id").autoincrement().primaryKey(),

  title: varchar("title", {
    length: 100,
  }).notNull().unique(),

  createdAt: timestamp("created_at").defaultNow(),
});
