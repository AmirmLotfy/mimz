import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';

// Hardcoded taxonomy for now, could be moved to Firestore later
const TAXONOMY = [
  {
    categoryId: 'tech',
    label: 'Technology & Engineering',
    tags: [
      { id: 'tech_software', label: 'Software Engineering' },
      { id: 'tech_ai', label: 'Artificial Intelligence' },
      { id: 'tech_hardware', label: 'Hardware & Gadgets' },
      { id: 'tech_cyber', label: 'Cybersecurity' },
      { id: 'tech_data', label: 'Data Science' }
    ]
  },
  {
    categoryId: 'science',
    label: 'Science & Nature',
    tags: [
      { id: 'sci_physics', label: 'Physics & Astronomy' },
      { id: 'sci_biology', label: 'Biology & Medicine' },
      { id: 'sci_chemistry', label: 'Chemistry' },
      { id: 'sci_earth', label: 'Earth & Environment' }
    ]
  },
  {
    categoryId: 'arts',
    label: 'Arts & Humanities',
    tags: [
      { id: 'art_history', label: 'World History' },
      { id: 'art_lit', label: 'Literature & Writing' },
      { id: 'art_design', label: 'Design & Visual Arts' },
      { id: 'art_music', label: 'Music Theory' }
    ]
  },
  {
    categoryId: 'business',
    label: 'Business & Economics',
    tags: [
      { id: 'biz_finance', label: 'Finance & Markets' },
      { id: 'biz_startups', label: 'Startups & VC' },
      { id: 'biz_marketing', label: 'Marketing' },
      { id: 'biz_econ', label: 'Macroeconomics' }
    ]
  },
  {
    categoryId: 'pop_culture',
    label: 'Pop Culture & Trivia',
    tags: [
      { id: 'pop_movies', label: 'Movies & TV' },
      { id: 'pop_gaming', label: 'Video Games' },
      { id: 'pop_sports', label: 'Sports' },
      { id: 'pop_music', label: 'Pop Music' }
    ]
  }
];

export async function interestsRoutes(server: FastifyInstance) {
  // GET /interests/taxonomy — Returns the categorized structured taxonomy
  server.get('/taxonomy', async (request: FastifyRequest, reply: FastifyReply) => {
    return { taxonomy: TAXONOMY };
  });
}
