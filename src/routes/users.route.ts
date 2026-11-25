
import { Router } from "express";

import UsersController from "../controllers/auth/users/users.controller";
import { authenticate } from "../controllers/middleware/auth.middleware";
import { uploadSingleImage } from "../controllers/middleware/upload.middleware";

const router = Router();

// Semua endpoint wajib login
router.get("/me", authenticate, UsersController.getProfile);

router.put("/me", authenticate, UsersController.updateName);

router.put(
  "/me/profile-photo",
  authenticate,
  uploadSingleImage,
  UsersController.updateProfilePhoto,
);

router.put(
  "/me/banner",
  authenticate,
  uploadSingleImage,
  UsersController.updateBanner,
);

export default router;
