# Interfaces

## Controller
```plantuml
@startuml
interface Controller {
  init_controller(m: matrix, online: boolean): void
  robot_step(): void
  controller_ended(): boolean
}
@enduml
```