-- Scripts de clase - Mayo 14 de 2025 
-- Curso de Tópicos Avanzados de base de datos - UPB 202510
-- Juan Dario Rodas - juand.rodasm@upb.edu.co

-- Proyecto: Analisis de Temperatura para Antioquia en 2024
-- Motor de Base de datos: MongoDB 7.x
-- Version: NoSQL Orientada al documento

-- *******************************************************
-- Consultas SQL con enfoque en la perspectiva temporal
-- *******************************************************

// Consulta básica - Las últimas 5 mediciones de una estación
db.mediciones.find(
  { estacion_id: ObjectId("6823daafb002c43a4993d4a5") },  // Estacion_id del metro de medellin
  { _id: 0, fecha: 1, valor: 1, unidad_medida: 1 }
).sort({ fecha: -1 }).limit(5);

// Consulta mejorada - Últimas 5 mediciones incluyendo el nombre de la estación
db.mediciones.aggregate([
  // Filtrar por una estación específica
  {
    $match: {
      estacion_id: ObjectId("6823daafb002c43a4993d4a5")  // Estacion_id del metro de medellin
    }
  },
  // Ordenar por fecha descendente y limitar a 5 resultados
  {
    $sort: { fecha: -1 }
  },
  {
    $limit: 5
  },
  // Hacer un "join" con la colección de estaciones para obtener el nombre
  {
    $lookup: {
      from: "estaciones",           // La colección con la que haremos el join
      localField: "estacion_id",    // Campo en la colección actual (observaciones)
      foreignField: "_id",          // Campo en la colección externa (estaciones)
      as: "info_estacion"           // Nombre del array donde se almacenarán los resultados
    }
  },
  // Convertir el array de estaciones en un objeto (siempre será un solo elemento)
  {
    $unwind: "$info_estacion"
  },
  // Dar formato a la salida para que sea más limpia
  {
    $project: {
      _id: 0,
      fecha: 1,
      nombre_estacion: "$info_estacion.nombre",
      valor: 1,
      unidad_medida: 1
    }
  }
]);

--Calcular la temperatura promedio, mínima y máxima de una 
--estación específica durante el mes de Septiembre de 2024

db.mediciones.aggregate([
  // Filtrar por estación y periodo
  {
    $match: {
      estacion_id: ObjectId("6823daafb002c43a4993d4a5"),
      fecha: {
        $gte: ISODate("2024-09-01T00:00:00Z"),
        $lt: ISODate("2024-10-01T00:00:00Z")
      }
    }
  },
  // Calcular estadísticas
  {
    $group: {
      _id: null,
      temperatura_promedio: { $avg: "$valor" },
      temperatura_minima: { $min: "$valor" },
      temperatura_maxima: { $max: "$valor" },
      total_mediciones: { $sum: 1 }
    }
  },
  // Formatear salida
  {
    $project: {
      _id: 0,
      temperatura_promedio: { $round: ["$temperatura_promedio", 2] },
      temperatura_minima: 1,
      temperatura_maxima: 1,
      total_mediciones: 1
    }
  }
]);


--Obtener la temperatura promedio por día para una estación específica 
-- durante la primera semana de septiembre 2024.

// Consulta con agrupación por día
db.mediciones.aggregate([
  // Filtrar por estación y periodo
  {
    $match: {
      estacion_id: ObjectId("6823daafb002c43a4993d4a5"),
      fecha: {
        $gte: ISODate("2024-09-01T00:00:00Z"),
        $lt: ISODate("2024-09-08T00:00:00Z")
      }
    }
  },
  // Agrupar por día
  {
    $group: {
      _id: { $dateToString: { format: "%Y-%m-%d", date: "$fecha" } },
      temperatura_promedio: { $avg: "$valor" },
      total_mediciones: { $sum: 1 }
    }
  },
  // Ordenar por día
  {
    $sort: { _id: 1 }
  },
  // Formatear salida
  {
    $project: {
      _id: 0,
      fecha: "$_id",
      temperatura_promedio: { $round: ["$temperatura_promedio", 2] },
      total_mediciones: 1
    }
  }
]);