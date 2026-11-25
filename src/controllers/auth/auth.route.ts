
import { Router } from "express";
import AuthController from "./auth.controller";

const router = Router();

// REGISTER
router.post("/register", AuthController.register);

// LOGIN
router.post("/login", AuthController.login);

export default router;
