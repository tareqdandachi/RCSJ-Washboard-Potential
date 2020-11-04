global tr phi_last L fr f update_counter I I_c

%% VARIABLES

Phi02pi = 1/(2*pi);%2.07e-15 / (2*pi);
R = 1;
C = 1;
L = 2; % length of pendulum

phi_last = [0 0]; %initial phi and dphi/dt
tr = linspace(0, 10, 1000); % time range
fr = 2; % frame rate

%% DO NOT MODIFY THESE VARIABLE

I = 0; % modified by UIControl
I_c = 2.5; % modified by UIControl
update_counter = 0; % modified by ode_stack

%% UI

f = figure(1);
ax = axes('Parent',f,'position',[0.13 0.39  0.77 0.54]);

bgcolor = f.Color;

note = uicontrol('Parent',f,'Style','text','Position',[125,80,300,23],...
                'BackgroundColor',bgcolor,...
                'String', 'the red line in $$V(\phi)$$ represents the path the state can reach');

bl1min = uicontrol('Parent',f,'Style','text','Position',[50,0,23,23],...
                'String','0','BackgroundColor',bgcolor);
bl1max = uicontrol('Parent',f,'Style','text','Position',[500,0,23,23],...
                'String','5','BackgroundColor',bgcolor);
bl1 = uicontrol('Parent',f,'Style','text','Position',[240,15,100,23],...
                'String','value of I','BackgroundColor',bgcolor);

bl2min = uicontrol('Parent',f,'Style','text','Position',[50,40,23,23],...
                'String','0','BackgroundColor',bgcolor);
bl2max = uicontrol('Parent',f,'Style','text','Position',[500,40,23,23],...
                'String','5','BackgroundColor',bgcolor);
bl2 = uicontrol('Parent',f,'Style','text','Position',[240,55,100,23],...
                'String','value of I_c','BackgroundColor',bgcolor);
            
b1 = uicontrol('Parent',f,'Style','slider','Position',[81,0,419,23],...
              'value',I, 'min',0, 'max',5, 'Value', I);
            
b2 = uicontrol('Parent',f,'Style','slider','Position',[81,40,419,23],...
              'value',I_c, 'min',0, 'max',5, 'Value', I_c);
            
b1.Callback = @(es,ed) stack_ode(es.Value, Phi02pi, NaN, R, C);
            
b2.Callback = @(es,ed) stack_ode(NaN, Phi02pi, es.Value, R, C);

%% ODE SOLVER AND QUEUE

ode_update(I, Phi02pi, I_c, R, C)

function sys = stack_ode(I_update, Phi02pi, I_c_update, R, C)

    global update_counter I I_c
    
    if ~isnan(I_update)
        I = I_update;
    elseif ~isnan(I_c_update)
        I_c = I_c_update;
    end
    
    update_counter = update_counter + 1;
    
    t = timer('StartDelay', 0.1, 'TimerFcn', ...
                @(src,evt) ode_update(I, Phi02pi, I_c, R, C));
    
    start(t)
    
end

function  sys  = ode_update(I, Phi02pi, I_c, R, C)

    global tr phi_last L fr f update_counter
    
    counter = update_counter;

    [ts, phis] = ode45(@(t, phi) func_dfpen(t, phi, Phi02pi, I, I_c, R, C) ...
                        ,tr, phi_last);

    x = [ L*sin(phis(:,1))];
    y = [-L*cos(phis(:,1))];
    
    for id = 1:fr:length(ts)
        
        k = update_counter;

        if ~ishghandle(f) || k ~= counter
            disp('removed stack')
            break
        end
        
        figure(1)

        phi_last = phis(id, :);

        subplot(4,2,2);
        plot(ts,phis(:,1), 'LineWidth', 0.5);
        line(ts(id), phis(id,1), 'Marker', '.', 'MarkerSize', 20, ...
            'Color', 'b');
        xlabel('time'); ylabel('\phi');

        subplot(4,2,4);
        plot(ts,phis(:,2), 'LineWidth', 0.5);
        line(ts(id), phis(id,2), 'Marker', '.', 'MarkerSize', 20, ...
             'Color', 'b');
        xlabel('time'); ylabel('$$\dot \phi$$', 'interpreter','latex');

        subplot(4,2,6);
        plot(ts, -I*ts-cos(ts), 'LineWidth', 0.7);
        line(phis(:,1), -I*phis(:,1)-cos(phis(:,1)), 'color', 'r', ...
            'LineWidth', 0.5);
        line(phis(id,1), -I*phis(id,1)-cos(phis(id,1)), 'Marker', '.', ...
            'MarkerSize', 20, 'Color', 'b');
        xlabel('\phi'); ylabel('$$V(\phi)$$', 'interpreter','latex');

        subplot(4,2,[1 3 5]);
        plot([0, x(id,1);], [0, y(id,1);], ...
            '.-', 'MarkerSize', 20, 'LineWidth', 2);
        axis equal; axis([-2*L 2*L -2*L 2*L]);
        title(sprintf('Time: %0.2f', ts(id)));

        drawnow;
    end
    
end

%% DIFF EQ

function  dphidt  = func_dfpen(t, phi, Phi02pi, I, I_c, R, C)
    dphidt(1) = phi(2);
    dphidt(2) = (- I_c * sin(phi(1)) - Phi02pi / R * phi(2) + I) /...
                (Phi02pi * C);
    dphidt=dphidt(:);
end