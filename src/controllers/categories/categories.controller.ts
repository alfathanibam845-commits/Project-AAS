
import { Request, Response } from "express";
import { eq } from "drizzle-orm";

import { db } from "../../config/db";
import { categoriesTable } from "../../config/schema";

class CategoriesController {
  // GET ALL CATEGORIES
  getCategories = async (_req: Request, res: Response) => {
    try {
      const categories = await db.query.categoriesTable.findMany();

      return res.status(200).json({
        success: true,
        data: { categories },
      });
    } catch (error) {
      console.error(error);
      return res.status(500).json({
        success: false,
        message: "Gagal mengambil kategori",
      });
    }
  };

  // CREATE CATEGORY
  createCategory = async (req: Request, res: Response) => {
    try {
      const title = String(req.body.title ?? "").trim();

      if (!title) {
        return res.status(400).json({
          success: false,
          message: "Nama kategori wajib diisi",
        });
      }

      const existing = await db.query.categoriesTable.findFirst({
        where: eq(categoriesTable.title, title),
      });

      if (existing) {
        return res.status(409).json({
          success: false,
          message: "Kategori sudah tersedia",
        });
      }

      const [inserted] = await db
        .insert(categoriesTable)
        .values({ title })
        .$returningId();

      const category = await db.query.categoriesTable.findFirst({
        where: eq(categoriesTable.id, inserted.id),
      });

      return res.status(201).json({
        success: true,
        message: "Kategori berhasil ditambahkan",
        data: { category },
      });
    } catch (error) {
      console.error("Create category error:", error);
      return res.status(500).json({
        success: false,
        message: "Gagal menambahkan kategori",
      });
    }
  };
}

export default new CategoriesController();
