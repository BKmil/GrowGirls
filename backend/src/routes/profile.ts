import { FastifyInstance } from "fastify";
import { z } from "zod";
import { prisma } from "../db";

type DbUser = {
  id: string;
  email: string;
  name: string | null;
  heightCm: number | null;
  weightKg: number | null;
  birthDate: Date | null;
};

function toProfile(u: DbUser) {
  return {
    id: u.id,
    email: u.email,
    name: u.name,
    heightCm: u.heightCm,
    weightKg: u.weightKg,
    birthDate: u.birthDate ? u.birthDate.toISOString().slice(0, 10) : null,
  };
}

const dateString = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Use format YYYY-MM-DD")
  .refine((s) => {
    const d = new Date(s + "T00:00:00.000Z");
    return !Number.isNaN(d.getTime()) && d.getTime() <= Date.now();
  }, "Invalid date or date in the future");

const updateSchema = z
  .object({
    name: z.string().trim().min(1).max(50).nullable(),
    heightCm: z.number().min(50).max(300).nullable(),
    weightKg: z.number().min(20).max(500).nullable(),
    birthDate: dateString.nullable(),
  })
  .partial()
  .strict();

export async function profileRoutes(app: FastifyInstance) {
  app.addHook("onRequest", app.authenticate);

  app.get("/", async (req, reply) => {
    const user = await prisma.user.findUnique({ where: { id: req.user.sub } });
    if (!user) return reply.code(404).send({ error: "User not found" });
    return toProfile(user);
  });

  app.patch("/", async (req, reply) => {
    const parsed = updateSchema.safeParse(req.body);
    if (!parsed.success) {
      return reply.code(400).send({
        error: "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
    }
    const { name, heightCm, weightKg, birthDate } = parsed.data;

    const user = await prisma.user.update({
      where: { id: req.user.sub },
      data: {
        name,
        heightCm,
        weightKg,
        birthDate:
          birthDate === undefined
            ? undefined
            : birthDate === null
              ? null
              : new Date(birthDate + "T00:00:00.000Z"),
      },
    });
    return toProfile(user);
  });
}