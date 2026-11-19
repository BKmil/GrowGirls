import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const exercises = [
  { name: "Barbell Bench Press", muscleGroup: "chest", instructions: "Lie on a bench, lower the bar to mid-chest under control, then press it up until your arms are straight. Keep your feet planted and shoulder blades pulled together." },
  { name: "Push-Up", muscleGroup: "chest", instructions: "Hands slightly wider than shoulders, body in a straight line. Lower your chest to just above the floor, then push back up." },
  { name: "Incline Dumbbell Press", muscleGroup: "chest", instructions: "On an incline bench, press the dumbbells up from shoulder height until your arms are straight, then lower slowly." },
  { name: "Pull-Up", muscleGroup: "back", instructions: "Hang from a bar with an overhand grip. Pull until your chin passes the bar, then lower with control." },
  { name: "Bent-Over Row", muscleGroup: "back", instructions: "Hinge at the hips with a flat back. Pull the weight toward your lower ribs, squeeze your shoulder blades, then lower." },
  { name: "Lat Pulldown", muscleGroup: "back", instructions: "Sit with thighs under the pad. Pull the bar to your upper chest while leaning back slightly, then let it rise slowly." },
  { name: "Overhead Press", muscleGroup: "shoulders", instructions: "Hold the weight at shoulder height. Press straight overhead until your arms are straight, keeping your core tight." },
  { name: "Lateral Raise", muscleGroup: "shoulders", instructions: "With a dumbbell in each hand, raise your arms out to the sides up to shoulder height, then lower slowly." },
  { name: "Dumbbell Curl", muscleGroup: "biceps", instructions: "Keep your elbows at your sides. Curl the dumbbells up to shoulder height, then lower without swinging." },
  { name: "Hammer Curl", muscleGroup: "biceps", instructions: "Hold the dumbbells with palms facing each other. Curl up and lower slowly, keeping your elbows still." },
  { name: "Triceps Dips", muscleGroup: "triceps", instructions: "Support yourself on parallel bars or a bench. Lower until your elbows reach about 90 degrees, then press back up." },
  { name: "Triceps Pushdown", muscleGroup: "triceps", instructions: "At a cable stack, keep your elbows pinned to your sides and push the handle down until your arms are straight." },
  { name: "Back Squat", muscleGroup: "legs", instructions: "Bar on your upper back. Sit down and back until your thighs are at least parallel to the floor, then stand up, knees tracking over toes." },
  { name: "Lunge", muscleGroup: "legs", instructions: "Step forward and lower until both knees are at about 90 degrees, then push through the front foot to return." },
  { name: "Leg Press", muscleGroup: "legs", instructions: "Feet shoulder-width on the platform. Lower the sled until your knees reach about 90 degrees, then press without locking out." },
  { name: "Romanian Deadlift", muscleGroup: "legs", instructions: "With soft knees, push your hips back and slide the weight down your thighs until you feel a hamstring stretch, then drive your hips forward." },
  { name: "Hip Thrust", muscleGroup: "glutes", instructions: "Upper back on a bench, weight on your hips. Drive your hips up until your body forms a straight line, squeeze, then lower." },
  { name: "Glute Bridge", muscleGroup: "glutes", instructions: "Lie on your back with knees bent. Lift your hips by squeezing your glutes, hold briefly, then lower." },
  { name: "Plank", muscleGroup: "core", instructions: "On your forearms and toes, keep your body in a straight line and your core tight. Hold without letting your hips sag." },
  { name: "Crunch", muscleGroup: "core", instructions: "Lie on your back with knees bent. Curl your shoulders off the floor using your abs, then lower slowly." },
  { name: "Russian Twist", muscleGroup: "core", instructions: "Sit leaning back with feet lifted. Rotate your torso side to side, moving your shoulders rather than just your arms." },
  { name: "Jump Rope", muscleGroup: "cardio", instructions: "Turn the rope with your wrists and hop lightly on the balls of your feet. Keep a steady rhythm." },
  { name: "Running", muscleGroup: "cardio", instructions: "Run at a steady pace with relaxed shoulders and a short, quick stride. Warm up first." },
  { name: "Burpee", muscleGroup: "full_body", instructions: "Squat down, kick your feet back into a plank, do a push-up, jump your feet in, then jump up with arms overhead." },
  { name: "Kettlebell Swing", muscleGroup: "full_body", instructions: "Hinge at the hips and swing the kettlebell back, then snap your hips forward to swing it to chest height. Power comes from the hips, not the arms." },
];

async function main() {
  let created = 0;
  for (const e of exercises) {
    const existing = await prisma.exercise.findFirst({
      where: { name: e.name, createdById: null },
    });
    if (!existing) {
      await prisma.exercise.create({ data: e });
      created++;
    }
  }
  console.log(`Seed done. Added ${created} exercises.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());