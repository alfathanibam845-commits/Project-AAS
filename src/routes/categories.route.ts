
import { Router } from "express";
import CategoriesController from "../controllers/categories/categories.controller";

const router = Router();

router.get("/", CategoriesController.getCategories);
router.post("/", CategoriesController.createCategory);

export default router;
