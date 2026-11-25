
import { Response } from "express";
import { eq } from "drizzle-orm";

import { db } from "../../../config/db";
import { usersTable } from "../../../config/schema";

import { AuthRequest } from "../../middleware/auth.middleware";

import {
  uploadToCloudinary,
  deleteFromCloudinary,
} from "../../../services/cloudinary.service";

class UsersController {
  // GET PROFILE
  getProfile = async (req: AuthRequest, res: Response) => {
    try {
      const userId = Number(req.user?.id);

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: "Unauthorized",
        });
      }

      const user = await db.query.usersTable.findFirst({
        where: eq(usersTable.id, userId),
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User tidak ditemukan",
        });
      }

      return res.status(200).json({
        success: true,
        message: "Profile berhasil diambil",
        data: {
          user: {
            id: user.id,
            username: user.username,
            email: user.email,
            profileImage: user.profileImage,
            bannerImage: user.bannerImage,
          },
        },
      });
    } catch (error) {
      console.error("Get profile error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal mengambil profile",
      });
    }
  };

  // UPDATE NAME
  updateName = async (req: AuthRequest, res: Response) => {
    try {
      const userId = Number(req.user?.id);
      const username = String(req.body.username ?? "").trim();

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: "Unauthorized",
        });
      }

      if (!username || username.length > 100) {
        return res.status(400).json({
          success: false,
          message: "Nama wajib diisi dan maksimal 100 karakter",
        });
      }

      await db
        .update(usersTable)
        .set({ username })
        .where(eq(usersTable.id, userId));

      return res.status(200).json({
        success: true,
        message: "Nama berhasil diperbarui",
        data: {
          username,
        },
      });
    } catch (error) {
      console.error("Update name error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal memperbarui nama",
      });
    }
  };

  // UPDATE PROFILE PHOTO
  updateProfilePhoto = async (req: AuthRequest, res: Response) => {
    try {
      const userId = Number(req.user?.id);

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: "Unauthorized",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Foto profil wajib dipilih",
        });
      }

      const user = await db.query.usersTable.findFirst({
        where: eq(usersTable.id, userId),
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User tidak ditemukan",
        });
      }

      const uploaded = await uploadToCloudinary(
        req.file.buffer,
        "profile",
      );

      try {
        await db
          .update(usersTable)
          .set({
            profileImage: uploaded.secure_url,
            profileImagePublicId: uploaded.public_id,
          })
          .where(eq(usersTable.id, userId));
      } catch (error) {
        await deleteFromCloudinary(uploaded.public_id);
        throw error;
      }

      if (user.profileImagePublicId) {
        try {
          await deleteFromCloudinary(user.profileImagePublicId);
        } catch (error) {
          console.error("Old profile image deletion error:", error);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Foto profil berhasil diperbarui",
        data: {
          profileImage: uploaded.secure_url,
        },
      });
    } catch (error) {
      console.error("Update profile photo error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal memperbarui foto profil",
      });
    }
  };

  // UPDATE BANNER
  updateBanner = async (req: AuthRequest, res: Response) => {
    try {
      const userId = Number(req.user?.id);

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: "Unauthorized",
        });
      }

      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: "Banner wajib dipilih",
        });
      }

      const user = await db.query.usersTable.findFirst({
        where: eq(usersTable.id, userId),
      });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: "User tidak ditemukan",
        });
      }

      const uploaded = await uploadToCloudinary(
        req.file.buffer,
        "banners",
      );

      try {
        await db
          .update(usersTable)
          .set({
            bannerImage: uploaded.secure_url,
            bannerImagePublicId: uploaded.public_id,
          })
          .where(eq(usersTable.id, userId));
      } catch (error) {
        await deleteFromCloudinary(uploaded.public_id);
        throw error;
      }

      if (user.bannerImagePublicId) {
        try {
          await deleteFromCloudinary(user.bannerImagePublicId);
        } catch (error) {
          console.error("Old banner deletion error:", error);
        }
      }

      return res.status(200).json({
        success: true,
        message: "Banner berhasil diperbarui",
        data: {
          bannerImage: uploaded.secure_url,
        },
      });
    } catch (error) {
      console.error("Update banner error:", error);

      return res.status(500).json({
        success: false,
        message: "Gagal memperbarui banner",
      });
    }
  };
}

export default new UsersController();
