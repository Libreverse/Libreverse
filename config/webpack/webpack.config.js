import { env } from 'shakapacker'
import { existsSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const environmentSpecificConfig = async () => {
  const extension = '.cjs'
  const configPath = path.resolve(__dirname, `${env.nodeEnv}${extension}`)
  if (!existsSync(configPath)) {
    throw new Error(`Could not find file to load ${configPath}, based on NODE_ENV`)
  }
  console.log(`Loading ENV specific webpack configuration file ${configPath}`)
  const mod = await import(pathToFileURL(configPath))
  return mod.default || mod
}

export default await environmentSpecificConfig()
