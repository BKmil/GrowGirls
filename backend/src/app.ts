import Fastify, { FastifyReply, FastifyRequest } from "fastify";
import cors from "@fastify/cors";
import jwt from "@fastify/jwt";
import { prisma } from "./db";
import { authRoutes } from "./routes/auth";
import { profileRoutes } from "./routes/profile";
import { exerciseRoutes } from "./routes/exercises";

declare module "fastify" {
  interface FastifyInstance {
    authenticate: (req: FastifyRequest, reply: FastifyReply) => Promise<unknown>;
  }
}

declare module "@fastify/jwt" {
  interface FastifyJWT {
    payload: { sub: string; ver: number };
    user: { sub: string; ver: number };
  }
}

export function buildApp() {
  const secret = process.env.JWT_SECRET;
  if (!secret) throw new Error("JWT_SECRET is not set in .env");

  const app = Fastify({ logger: true });

  app.register(cors, { origin: true });
  app.register(jwt, { secret, sign: { expiresIn: "7d" } });

  app.decorate("authenticate", async (req: FastifyRequest, reply: FastifyReply) => {
    try {
      await req.jwtVerify();
    } catch {
      return reply.code(401).send({ error: "Unauthorized" });
    }
    const user = await prisma.user.findUnique({
      where: { id: req.user.sub },
      select: { tokenVersion: true },
    });
    if (!user || user.tokenVersion !== req.user.ver) {
      return reply.code(401).send({ error: "Unauthorized" });
    }
  });

  app.get("/health", async () => ({ status: "ok" }));
  app.register(authRoutes, { prefix: "/auth" });
  app.register(profileRoutes, { prefix: "/profile" });
  app.register(exerciseRoutes, { prefix: "/exercises" });

  return app;
}