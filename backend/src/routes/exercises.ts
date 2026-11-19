import { FastifyInstance } from "fastify";
import { Prisma } from "@prisma/client";
import { z } from "zod";
import { prisma } from "../db";

export const MUSCLE_GROUPS = [
  "chest",
  "back",
  "shoulders",
  "biceps",
  "triceps",
  "legs",
  "glutes",
  "core",
  "cardio",
  "full_body",
] as const;

const listQuery = z.object({
  search: z.string().trim().max(100).optional(),
  muscleGroup: z.enum(MUSCLE_GROUPS).optional(),
  favoritesOnly: z.enum(["true", "false"]).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// built-in exercises (createdById = null) + the user's own custom ones
function visibleTo(userId: string): Prisma.ExerciseWhereInput {
  return { OR: [{ createdById: null }, { createdById: userId }] };
}

function withFavorites(userId: string) {
  return {
    favorites: { where: { userId }, select: { userId: true } },
  } as const;
}

type ExerciseRow = {
  id: string;
  name: string;
  muscleGroup: string;
  instructions: string;
  mediaUrl: string | null;
  mediaType: string | null;
  createdById: string | null;
  favorites: { userId: string }[];
};

function toDto(e: ExerciseRow) {
  return {
    id: e.id,
    name: e.name,
    muscleGroup: e.muscleGroup,
    instructions: e.instructions,
    mediaUrl: e.mediaUrl,
    mediaType: e.mediaType,
    isCustom: e.createdById !== null,
    isFavorite: e.favorites.length > 0,
  };
}

export async function exerciseRoutes(app: FastifyInstance) {
  app.addHook("onRequest", app.authenticate);

  app.get("/muscle-groups", async () => ({ items: MUSCLE_GROUPS }));

  app.get("/", async (req, reply) => {
    const parsed = listQuery.safeParse(req.query);
    if (!parsed.success) {
      return reply.code(400).send({
        error: "Validation failed",
        details: parsed.error.flatten().fieldErrors,
      });
    }
    const { search, muscleGroup, favoritesOnly, page, limit } = parsed.data;
    const userId = req.user.sub;

    const filters: Prisma.ExerciseWhereInput[] = [visibleTo(userId)];
    if (search) filters.push({ name: { contains: search } });
    if (muscleGroup) filters.push({ muscleGroup });
    if (favoritesOnly === "true") filters.push({ favorites: { some: { userId } } });
    const where: Prisma.ExerciseWhereInput = { AND: filters };

    const [total, rows] = await prisma.$transaction([
      prisma.exercise.count({ where }),
      prisma.exercise.findMany({
        where,
        orderBy: { name: "asc" },
        skip: (page - 1) * limit,
        take: limit,
        include: withFavorites(userId),
      }),
    ]);

    return { items: rows.map(toDto), page, limit, total };
  });

  app.get("/:id", async (req, reply) => {
    const { id } = req.params as { id: string };
    const userId = req.user.sub;

    const exercise = await prisma.exercise.findFirst({
      where: { AND: [{ id }, visibleTo(userId)] },
      include: withFavorites(userId),
    });
    if (!exercise) return reply.code(404).send({ error: "Exercise not found" });

    // prHistory will be filled once workout logging (#21) exists
    return { ...toDto(exercise), prHistory: [] };
  });

  app.put("/:id/favorite", async (req, reply) => {
    const { id } = req.params as { id: string };
    const userId = req.user.sub;

    const exercise = await prisma.exercise.findFirst({
      where: { AND: [{ id }, visibleTo(userId)] },
      select: { id: true },
    });
    if (!exercise) return reply.code(404).send({ error: "Exercise not found" });

    await prisma.favorite.upsert({
      where: { userId_exerciseId: { userId, exerciseId: id } },
      create: { userId, exerciseId: id },
      update: {},
    });
    return reply.code(204).send();
  });

  app.delete("/:id/favorite", async (req, reply) => {
    const { id } = req.params as { id: string };
    const userId = req.user.sub;

    await prisma.favorite.deleteMany({ where: { userId, exerciseId: id } });
    return reply.code(204).send();
  });
}