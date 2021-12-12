# Modules
import os
os.environ['PYGAME_HIDE_SUPPORT_PROMPT'] = "hide"
import pygame
import pygame_gui

# Colors
black = (0, 0, 0)
white = (255, 255, 255)
green = (0, 255, 0)
blue = (0, 0, 128)

# Window
pygame.init()
pygame.font.init()
screen = pygame.display.set_mode((600, 400))
screen.fill(white)
pygame.display.flip()
background = pygame.Surface((600, 400))
background.fill(white)
pygame.display.set_caption('Lrdsnow\'s Multi-Tool')
applicationicon = pygame.image.load('lmt-gui-icon.png')
pygame.display.set_icon(applicationicon)
manager = pygame_gui.UIManager((600, 400))
clock = pygame.time.Clock()
done = False
myfont=pygame.font.SysFont('lmt-gui-font.ttf',  30)
textsurface = myfont.render('LMT', False, black)
screen.blit(textsurface,(0,0))
hello_button = pygame_gui.elements.UIButton(relative_rect=pygame.Rect((round(240), round(350)), (round(100), round(50))),
                                             text='Quit',
                                             manager=manager)

# Runtime
while not done:
        time_delta = clock.tick(60)/1000.0
        for event in pygame.event.get():
                if event.type == pygame.QUIT:
                        done = True

                if event.type == pygame.USEREVENT:
                    if event.user_type == pygame_gui.UI_BUTTON_PRESSED:
                        if event.ui_element == hello_button:
                            done = True

                manager.process_events(event)

        manager.update(time_delta)

        screen.blit(background, (0, 0))
        manager.draw_ui(screen)

        pygame.display.flip()
