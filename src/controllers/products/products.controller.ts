import { Request, Response } from "express";
import { eq } from "drizzle-orm";

import { db } from "../../config/db";
import { productsTable } from "../../config/schema";

import {
  uploadToCloudinary,
  deleteFromCloudinary,
} from "../../services/cloudinary.service";

import { AuthRequest } from "../middleware/auth.middleware";

// ==========================================
// CHECKOUT ERROR
// ==========================================

class CheckoutError extends Error {
  constructor(
    public statusCode: number,
    message: string,
  ) {
    super(message);
    this.name = "CheckoutError";
  }
}

class ProductsController {
  // ==========================================
  // CREATE PRODUCT
  // ==========================================

  createProduct = async (req: AuthRequest, res: Response) => {
    try {
      const { name, category, price, stock, description } = req.body;

      if (
        !name ||
        !category ||
        price === undefined ||
        stock === undefined
      ) {
        return res.status(400).json({
          success: false,
          message: "Nama, kategori, harga, dan stok wajib diisi",
        });
      }

      const parsedPrice = Number(price);
      const parsedStock = Number(stock);

      if (
        !Number.isFinite(parsedPrice) ||
        parsedPrice < 0 ||
        !Number.isInteger(parsedStock) ||
        parsedStock < 0
      ) {
        return res.status(400).json({
          success: false,
          message: "Harga atau stok tidak valid",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Gambar produk wajib diunggah",
        });
      }

      const uploadedImage = await uploadToCloudinary(req.file.buffer);

      const [insertedProduct] = await db
        .insert(productsTable)
        .values({
          name: String(name).trim(),
          category: String(category).trim(),
          price: parsedPrice.toFixed(2),
          stock: parsedStock,
          description: description ? String(description) : null,
          imageUrl: uploadedImage.secure_url,
          imagePublicId: uploadedImage.public_id,
        })
        .$returningId();

      const newProduct = await db.query.productsTable.findFirst({
        where: eq(productsTable.id, insertedProduct.id),
      });

      return res.status(201).json({
        success: true,
        message: "Product created successfully",
        data: {
          product: newProduct,
        },
      });
    } catch (error) {
      console.error("Create product error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal membuat produk",
      });
    }
  };

  // ==========================================
  // GET ALL PRODUCTS
  // ==========================================

  getProducts = async (_req: AuthRequest, res: Response) => {
    try {
      const products = await db.query.productsTable.findMany();

      return res.status(200).json({
        success: true,
        data: {
          products,
        },
      });
    } catch (error) {
      console.error("Get products error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal mengambil produk",
      });
    }
  };

  // ==========================================
  // GET PRODUCT BY ID
  // ==========================================

  getProductById = async (req: Request, res: Response) => {
    try {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({
          success: false,
          message: "ID produk tidak valid",
        });
      }

      const product = await db.query.productsTable.findFirst({
        where: eq(productsTable.id, id),
      });

      if (!product) {
        return res.status(404).json({
          success: false,
          message: "Produk tidak ditemukan",
        });
      }

      return res.status(200).json({
        success: true,
        data: {
          product,
        },
      });
    } catch (error) {
      console.error("Get product detail error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal mengambil detail produk",
      });
    }
  };

  // ==========================================
  // UPDATE PRODUCT
  // ==========================================

  updateProduct = async (req: AuthRequest, res: Response) => {
    let uploadedNewImage: {
      secure_url: string;
      public_id: string;
    } | null = null;

    try {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({
          success: false,
          message: "ID produk tidak valid",
        });
      }

      const existingProduct = await db.query.productsTable.findFirst({
        where: eq(productsTable.id, id),
      });

      if (!existingProduct) {
        return res.status(404).json({
          success: false,
          message: "Produk tidak ditemukan",
        });
      }

      const { name, category, price, stock, description } = req.body;

      if (
        !name ||
        !category ||
        price === undefined ||
        stock === undefined
      ) {
        return res.status(400).json({
          success: false,
          message: "Nama, kategori, harga, dan stok wajib diisi",
        });
      }

      const parsedPrice = Number(price);
      const parsedStock = Number(stock);

      if (
        !Number.isFinite(parsedPrice) ||
        parsedPrice < 0 ||
        !Number.isInteger(parsedStock) ||
        parsedStock < 0
      ) {
        return res.status(400).json({
          success: false,
          message: "Harga atau stok tidak valid",
        });
      }

      if (req.file) {
        uploadedNewImage = await uploadToCloudinary(req.file.buffer);
      }

      await db
        .update(productsTable)
        .set({
          name: String(name).trim(),
          category: String(category).trim(),
          price: parsedPrice.toFixed(2),
          stock: parsedStock,
          description: description ? String(description) : null,

          ...(uploadedNewImage
            ? {
                imageUrl: uploadedNewImage.secure_url,
                imagePublicId: uploadedNewImage.public_id,
              }
            : {}),
        })
        .where(eq(productsTable.id, id));

      // Hapus gambar lama jika gambar diganti.
      if (uploadedNewImage && existingProduct.imagePublicId) {
        try {
          await deleteFromCloudinary(existingProduct.imagePublicId);
        } catch (imageError) {
          console.error("Old Cloudinary image cleanup error:", imageError);
        }
      }

      const updatedProduct = await db.query.productsTable.findFirst({
        where: eq(productsTable.id, id),
      });

      return res.status(200).json({
        success: true,
        message: "Produk berhasil diperbarui",
        data: {
          product: updatedProduct,
        },
      });
    } catch (error) {
      console.error("Update product error:", error);

      if (uploadedNewImage) {
        try {
          await deleteFromCloudinary(uploadedNewImage.public_id);
        } catch (cleanupError) {
          console.error("New image cleanup error:", cleanupError);
        }
      }

      return res.status(500).json({
        success: false,
        message: "Gagal memperbarui produk",
      });
    }
  };

  // ==========================================
  // CHECKOUT / REDUCE PRODUCT STOCK
  // ==========================================

  checkout = async (req: AuthRequest, res: Response) => {
    try {
      const { items } = req.body;

      if (!Array.isArray(items) || items.length === 0) {
        return res.status(400).json({
          success: false,
          message: "Daftar produk tidak boleh kosong",
        });
      }

      // Validasi dan gabungkan produk dengan ID yang sama.
      const quantityMap = new Map<number, number>();

      for (const item of items) {
        const productId = Number(item.productId);
        const quantity = Number(item.quantity);

        if (
          !Number.isInteger(productId) ||
          productId <= 0 ||
          !Number.isInteger(quantity) ||
          quantity <= 0
        ) {
          return res.status(400).json({
            success: false,
            message: "ID produk atau jumlah pembelian tidak valid",
          });
        }

        quantityMap.set(
          productId,
          (quantityMap.get(productId) ?? 0) + quantity,
        );
      }

      // Urutkan ID untuk menjaga urutan penguncian baris.
      const purchases = Array.from(quantityMap.entries())
        .map(([productId, quantity]) => ({
          productId,
          quantity,
        }))
        .sort((a, b) => a.productId - b.productId);

      // Semua pengurangan stok berada dalam satu transaksi.
      const updatedProducts = await db.transaction(async (tx) => {
        const results = [];

        for (const purchase of purchases) {
          // Kunci baris produk selama transaksi berlangsung.
          const [product] = await tx
            .select()
            .from(productsTable)
            .where(eq(productsTable.id, purchase.productId))
            .limit(1)
            .for("update");

          if (!product) {
            throw new CheckoutError(
              404,
              `Produk dengan ID ${purchase.productId} tidak ditemukan`,
            );
          }

          if (product.stock < purchase.quantity) {
            throw new CheckoutError(
              409,
              `Stok ${product.name} tidak mencukupi. Stok tersedia: ${product.stock}`,
            );
          }

          const newStock = product.stock - purchase.quantity;

          await tx
            .update(productsTable)
            .set({
              stock: newStock,
            })
            .where(eq(productsTable.id, purchase.productId));

          results.push({
            id: product.id,
            name: product.name,
            purchased: purchase.quantity,
            stock: newStock,
          });
        }

        return results;
      });

      return res.status(200).json({
        success: true,
        message: "Checkout berhasil. Stok produk telah diperbarui.",
        data: {
          products: updatedProducts,
        },
      });
    } catch (error) {
      console.error("Checkout error:", error);

      if (error instanceof CheckoutError) {
        return res.status(error.statusCode).json({
          success: false,
          message: error.message,
        });
      }

      return res.status(500).json({
        success: false,
        message: "Checkout gagal. Silakan coba kembali.",
      });
    }
  };

  // ==========================================
  // DELETE PRODUCT
  // ==========================================

  deleteProduct = async (req: AuthRequest, res: Response) => {
    try {
      const id = Number(req.params.id);

      if (!Number.isInteger(id) || id <= 0) {
        return res.status(400).json({
          success: false,
          message: "ID produk tidak valid",
        });
      }

      const product = await db.query.productsTable.findFirst({
        where: eq(productsTable.id, id),
      });

      if (!product) {
        return res.status(404).json({
          success: false,
          message: "Produk tidak ditemukan",
        });
      }

      await db
        .delete(productsTable)
        .where(eq(productsTable.id, id));

      if (product.imagePublicId) {
        try {
          await deleteFromCloudinary(product.imagePublicId);
        } catch (imageError) {
          console.error("Cloudinary image cleanup error:", imageError);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Produk berhasil dihapus",
      });
    } catch (error) {
      console.error("Delete product error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal menghapus produk",
      });
    }
  };
}

export default new ProductsController();