
import { v2 as cloudinary } from "cloudinary";
import dotenv from "dotenv";
import path from "path";

dotenv.config({
  path: path.resolve(process.cwd(), ".env"),
});

const cloudName = process.env.CLD_CLOUD_NAME;
const apiKey = process.env.CLD_API_KEY;
const apiSecret = process.env.CLD_API_SECRET;

if (!cloudName || !apiKey || !apiSecret) {
  throw new Error("Konfigurasi Cloudinary belum lengkap. Periksa .env");
}

cloudinary.config({
  cloud_name: cloudName,
  api_key: apiKey,
  api_secret: apiSecret,
});

console.log("CLOUDINARY CONFIG STATUS: TERBACA");

export default cloudinary;
