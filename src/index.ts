import dotenv from "dotenv";
dotenv.config({ path: ".env" });
import express from "express";
import cors from "cors";

import authRoute from "./controllers/auth/auth.route";
import productsRoute from "./routes/products.route";
import usersRoute from "./routes/users.route";
import categoriesRoute from "./routes/categories.route";

const app = express();
const PORT = Number(process.env.PORT) || 5002;

console.log(
  "JWT SECRET STATUS:",
  process.env.JWT_SECRET ? "TERBACA" : "TIDAK TERBACA"
);

app.use(cors({ origin: true }));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.use("/api/v1/auth", authRoute);
app.use("/api/v1/products", productsRoute);
app.use("/api/v1/users", usersRoute);
app.use("/api/v1/categories", categoriesRoute);

app.get("/", (_req, res) => {
  res.json({
    success: true,
    message: "Product Management API berjalan",
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server berjalan di http://localhost:${PORT}`);
});

