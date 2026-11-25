import { Router } from "express";

import ProductsController from "../controllers/products/products.controller";

import {
  authenticate,
  requireAdmin,
} from "../controllers/middleware/auth.middleware";

import { uploadSingleImage } from "../controllers/middleware/upload.middleware";

const router = Router();

// ==========================================
// ADMIN ONLY
// ==========================================

// CREATE PRODUCT
router.post(
  "/",
  authenticate,
  requireAdmin,
  uploadSingleImage,
  ProductsController.createProduct,
);

// UPDATE PRODUCT
router.put(
  "/:id",
  authenticate,
  requireAdmin,
  uploadSingleImage,
  ProductsController.updateProduct,
);

// DELETE PRODUCT
router.delete(
  "/:id",
  authenticate,
  requireAdmin,
  ProductsController.deleteProduct,
);

// ==========================================
// ADMIN & USER
// ==========================================

// CHECKOUT PRODUCT
router.post(
  "/checkout",
  authenticate,
  ProductsController.checkout,
);

// READ ALL PRODUCTS
router.get(
  "/",
  authenticate,
  ProductsController.getProducts,
);

router.post(
  "/checkout",
  authenticate,
  ProductsController.checkout,
);

// READ PRODUCT DETAIL
router.get(
  "/:id",
  authenticate,
  ProductsController.getProductById,
);

export default router;